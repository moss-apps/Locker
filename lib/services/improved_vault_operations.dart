import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/vaulted_file.dart';
import 'encryption_service.dart';
import 'improved_compression_service.dart';

/// Improved vault operations with cancellation and rollback support
class ImprovedVaultOperations {
  final EncryptionService _encryptionService = EncryptionService.instance;
  final ImprovedCompressionService _compressionService = ImprovedCompressionService.instance;

  /// Add file to vault with progress tracking and cancellation support
  Future<VaultFileResult> addFileToVault({
    required String sourcePath,
    required VaultedFileType type,
    required String vaultPath,
    required String taskId,
    bool compress = false,
    bool encrypt = true,
    bool isDecoy = false,
    Function(VaultOperationProgress progress)? onProgress,
  }) async {
    final rollbackActions = <Future<void> Function()>[];
    String? tempCompressedPath;
    String? tempEncryptedPath;

    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return VaultFileResult.error('Source file does not exist');
      }

      var currentPath = sourcePath;
      final originalSize = await sourceFile.length();
      final isLargeFile = originalSize > 5 * 1024 * 1024;

      // Step 1: Compression (if enabled and applicable)
      if (compress && type == VaultedFileType.video) {
        onProgress?.call(VaultOperationProgress(
          stage: VaultOperationStage.compressing,
          progress: 0.0,
          message: 'Compressing video...',
        ));

        final compressionResult = await _compressionService.compressVideo(
          sourcePath: currentPath,
          taskId: taskId,
          quality: VideoCompressionQuality.medium,
          onProgress: (progress) {
            onProgress?.call(VaultOperationProgress(
              stage: VaultOperationStage.compressing,
              progress: progress,
              message: 'Compressing video... ${(progress * 100).toInt()}%',
            ));
          },
        );

        if (compressionResult == null) {
          // Cancelled or failed
          return VaultFileResult.cancelled();
        }

        if (!compressionResult.skipped) {
          tempCompressedPath = compressionResult.compressedPath;
          currentPath = tempCompressedPath;

          // Add rollback action to delete compressed file
          rollbackActions.add(() async {
            if (tempCompressedPath != null) {
              final file = File(tempCompressedPath);
              if (await file.exists()) {
                await file.delete();
                debugPrint('[VaultOps] Rollback: Deleted compressed file');
              }
            }
          });
        }
      }

      // Step 2: Encryption
      if (encrypt) {
        onProgress?.call(VaultOperationProgress(
          stage: VaultOperationStage.encrypting,
          progress: 0.0,
          message: 'Encrypting file...',
        ));

        FileEncryptionResult encResult;
        if (isLargeFile) {
          encResult = await _encryptionService.encryptFileStreamed(
            currentPath,
            vaultPath,
            isDecoy: isDecoy,
            onProgress: (current, total) {
              final progress = current / total;
              onProgress?.call(VaultOperationProgress(
                stage: VaultOperationStage.encrypting,
                progress: progress,
                message: 'Encrypting file... ${(progress * 100).toInt()}%',
              ));
            },
          );
        } else {
          encResult = await _encryptionService.encryptFile(
            currentPath,
            vaultPath,
            isDecoy: isDecoy,
            onProgress: (current, total) {
              final progress = current / total;
              onProgress?.call(VaultOperationProgress(
                stage: VaultOperationStage.encrypting,
                progress: progress,
                message: 'Encrypting file... ${(progress * 100).toInt()}%',
              ));
            },
          );
        }

        if (!encResult.success) {
          // Rollback compression if it happened
          await _performRollback(rollbackActions);
          return VaultFileResult.error(encResult.error ?? 'Encryption failed');
        }

        tempEncryptedPath = vaultPath;

        // Add rollback action to delete encrypted file
        rollbackActions.add(() async {
          final file = File(vaultPath);
          if (await file.exists()) {
            await file.delete();
            debugPrint('[VaultOps] Rollback: Deleted encrypted file');
          }
        });

        // Cleanup compressed temp file if it exists
        if (tempCompressedPath != null && tempCompressedPath != sourcePath) {
          try {
            await File(tempCompressedPath).delete();
            debugPrint('[VaultOps] Cleaned up compressed temp file');
          } catch (e) {
            debugPrint('[VaultOps] Could not delete temp compressed file: $e');
          }
        }

        onProgress?.call(VaultOperationProgress(
          stage: VaultOperationStage.complete,
          progress: 1.0,
          message: 'File added to vault',
        ));

        return VaultFileResult.success(
          vaultPath: vaultPath,
          encryptionIv: encResult.iv,
          originalSize: originalSize,
          finalSize: encResult.encryptedSize ?? originalSize,
        );
      } else {
        // No encryption, just copy
        onProgress?.call(VaultOperationProgress(
          stage: VaultOperationStage.copying,
          progress: 0.5,
          message: 'Copying file...',
        ));

        if (isLargeFile) {
          await _streamCopyFile(File(currentPath), File(vaultPath));
        } else {
          await File(currentPath).copy(vaultPath);
        }

        // Cleanup compressed temp file if it exists
        if (tempCompressedPath != null && tempCompressedPath != sourcePath) {
          try {
            await File(tempCompressedPath).delete();
          } catch (e) {
            debugPrint('[VaultOps] Could not delete temp compressed file: $e');
          }
        }

        onProgress?.call(VaultOperationProgress(
          stage: VaultOperationStage.complete,
          progress: 1.0,
          message: 'File added to vault',
        ));

        return VaultFileResult.success(
          vaultPath: vaultPath,
          originalSize: originalSize,
          finalSize: await File(vaultPath).length(),
        );
      }
    } catch (e) {
      debugPrint('[VaultOps] Error adding file to vault: $e');
      
      // Perform rollback
      await _performRollback(rollbackActions);
      
      return VaultFileResult.error('Failed to add file: $e');
    }
  }

  /// Cancel vault operation
  Future<bool> cancelOperation(String taskId) async {
    try {
      // Cancel compression if active
      final cancelled = await _compressionService.cancelCompression(taskId);
      
      if (cancelled) {
        debugPrint('[VaultOps] Operation cancelled: $taskId');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('[VaultOps] Error cancelling operation: $e');
      return false;
    }
  }

  /// Perform rollback actions in reverse order
  Future<void> _performRollback(List<Future<void> Function()> actions) async {
    debugPrint('[VaultOps] Performing rollback (${actions.length} actions)');
    
    for (final action in actions.reversed) {
      try {
        await action();
      } catch (e) {
        debugPrint('[VaultOps] Rollback action failed: $e');
      }
    }
  }

  /// Stream copy a file in chunks
  Future<void> _streamCopyFile(File source, File destination) async {
    final sink = destination.openWrite();
    await source.openRead().pipe(sink);
  }
}

/// Result of vault file operation
class VaultFileResult {
  final bool success;
  final bool cancelled;
  final String? vaultPath;
  final String? encryptionIv;
  final int? originalSize;
  final int? finalSize;
  final String? error;

  VaultFileResult._({
    required this.success,
    this.cancelled = false,
    this.vaultPath,
    this.encryptionIv,
    this.originalSize,
    this.finalSize,
    this.error,
  });

  factory VaultFileResult.success({
    required String vaultPath,
    String? encryptionIv,
    required int originalSize,
    required int finalSize,
  }) {
    return VaultFileResult._(
      success: true,
      vaultPath: vaultPath,
      encryptionIv: encryptionIv,
      originalSize: originalSize,
      finalSize: finalSize,
    );
  }

  factory VaultFileResult.error(String error) {
    return VaultFileResult._(
      success: false,
      error: error,
    );
  }

  factory VaultFileResult.cancelled() {
    return VaultFileResult._(
      success: false,
      cancelled: true,
      error: 'Operation cancelled by user',
    );
  }
}

/// Progress information for vault operations
class VaultOperationProgress {
  final VaultOperationStage stage;
  final double progress; // 0.0 to 1.0
  final String message;

  VaultOperationProgress({
    required this.stage,
    required this.progress,
    required this.message,
  });
}

/// Stages of vault operation
enum VaultOperationStage {
  compressing,
  encrypting,
  copying,
  complete,
}
