import 'package:flutter/foundation.dart';
import '../models/vaulted_file.dart';
import '../services/vault_service.dart';
import 'encryption_diagnostics.dart';

/// Utility to check and fix vault files
class VaultFileChecker {
  /// Check all vault files for corruption
  static Future<CheckResult> checkAllFiles({bool isDecoy = false}) async {
    final files = await VaultService.instance.getAllFiles(isDecoy: isDecoy);
    final corrupted = <VaultedFile>[];
    final valid = <VaultedFile>[];
    final errors = <String, String>{};

    debugPrint('[VaultChecker] Checking ${files.length} files...');

    for (final file in files) {
      if (!file.isEncrypted) {
        valid.add(file);
        continue;
      }

      try {
        final diag = await EncryptionDiagnostics.analyzeFile(file.vaultPath);

        if (!diag.exists) {
          errors[file.id] = 'File does not exist';
          corrupted.add(file);
        } else if (diag.error != null) {
          errors[file.id] = diag.error!;
          corrupted.add(file);
        } else if (!diag.validForCbc && 
                   (diag.format == EncryptionFormat.legacyCbc || 
                    diag.format == EncryptionFormat.cbcWithHeader)) {
          errors[file.id] = 'Invalid CBC data length: ${diag.dataLength} bytes (remainder: ${diag.remainder})';
          corrupted.add(file);
          debugPrint('[VaultChecker] Corrupted: ${file.originalName} - ${errors[file.id]}');
        } else {
          valid.add(file);
        }
      } catch (e) {
        errors[file.id] = 'Error checking file: $e';
        corrupted.add(file);
      }
    }

    debugPrint('[VaultChecker] Results: ${valid.length} valid, ${corrupted.length} corrupted');

    return CheckResult(
      totalFiles: files.length,
      validFiles: valid,
      corruptedFiles: corrupted,
      errors: errors,
    );
  }

  /// Remove corrupted files from vault
  static Future<int> removeCorruptedFiles(List<VaultedFile> corruptedFiles) async {
    int removed = 0;

    for (final file in corruptedFiles) {
      try {
        final success = await VaultService.instance.removeFile(
          file.id,
          isDecoy: file.isDecoy,
        );
        if (success) {
          removed++;
          debugPrint('[VaultChecker] Removed: ${file.originalName}');
        }
      } catch (e) {
        debugPrint('[VaultChecker] Error removing ${file.originalName}: $e');
      }
    }

    debugPrint('[VaultChecker] Removed $removed of ${corruptedFiles.length} corrupted files');
    return removed;
  }

  /// Generate a report of vault health
  static Future<String> generateHealthReport({bool isDecoy = false}) async {
    final result = await checkAllFiles(isDecoy: isDecoy);
    
    final buffer = StringBuffer();
    buffer.writeln('=== Vault Health Report ===');
    buffer.writeln('Vault Type: ${isDecoy ? "Decoy" : "Main"}');
    buffer.writeln('Total Files: ${result.totalFiles}');
    buffer.writeln('Valid Files: ${result.validFiles.length}');
    buffer.writeln('Corrupted Files: ${result.corruptedFiles.length}');
    buffer.writeln('Health: ${result.healthPercentage.toStringAsFixed(1)}%');
    buffer.writeln('');

    if (result.corruptedFiles.isNotEmpty) {
      buffer.writeln('Corrupted Files:');
      for (final file in result.corruptedFiles) {
        final error = result.errors[file.id] ?? 'Unknown error';
        buffer.writeln('  - ${file.originalName}');
        buffer.writeln('    Error: $error');
        buffer.writeln('    Path: ${file.vaultPath}');
        buffer.writeln('    Size: ${_formatBytes(file.fileSize)}');
        buffer.writeln('');
      }
    }

    buffer.writeln('===========================');
    return buffer.toString();
  }

  /// Print health report to console
  static Future<void> printHealthReport({bool isDecoy = false}) async {
    final report = await generateHealthReport(isDecoy: isDecoy);
    debugPrint(report);
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Result of vault file check
class CheckResult {
  final int totalFiles;
  final List<VaultedFile> validFiles;
  final List<VaultedFile> corruptedFiles;
  final Map<String, String> errors;

  CheckResult({
    required this.totalFiles,
    required this.validFiles,
    required this.corruptedFiles,
    required this.errors,
  });

  double get healthPercentage {
    if (totalFiles == 0) return 100.0;
    return (validFiles.length / totalFiles) * 100;
  }

  bool get hasCorruption => corruptedFiles.isNotEmpty;

  bool get isHealthy => healthPercentage >= 95.0;
}
