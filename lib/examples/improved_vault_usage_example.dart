import 'package:flutter/material.dart';
import '../services/improved_vault_operations.dart';
import '../services/improved_compression_service.dart';
import '../widgets/vault_operation_progress_dialog.dart';
import '../models/vaulted_file.dart';

/// Example showing how to use the improved vault operations with progress and cancellation
class ImprovedVaultUsageExample extends StatefulWidget {
  const ImprovedVaultUsageExample({Key? key}) : super(key: key);

  @override
  State<ImprovedVaultUsageExample> createState() => _ImprovedVaultUsageExampleState();
}

class _ImprovedVaultUsageExampleState extends State<ImprovedVaultUsageExample> {
  final ImprovedVaultOperations _vaultOps = ImprovedVaultOperations();
  String? _currentTaskId;

  /// Example: Add file to vault with progress tracking
  Future<void> _addFileToVault(String sourcePath) async {
    final result = await showVaultOperationProgress<VaultFileResult>(
      context: context,
      title: 'Adding to Vault',
      operation: (onProgress, taskId) async {
        _currentTaskId = taskId;
        
        return await _vaultOps.addFileToVault(
          sourcePath: sourcePath,
          type: VaultedFileType.video,
          vaultPath: '/path/to/vault/encrypted_file.enc',
          taskId: taskId,
          compress: true,
          encrypt: true,
          onProgress: onProgress,
        );
      },
      onCancel: () async {
        if (_currentTaskId != null) {
          await _vaultOps.cancelOperation(_currentTaskId!);
        }
      },
    );

    if (!mounted) return;

    if (result != null) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File added successfully! '
              'Original: ${_formatBytes(result.originalSize ?? 0)}, '
              'Final: ${_formatBytes(result.finalSize ?? 0)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operation cancelled. All changes have been reverted.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Example: Add multiple files with batch progress
  Future<void> _addMultipleFiles(List<String> filePaths) async {
    int completed = 0;
    int failed = 0;
    int cancelled = 0;

    for (final path in filePaths) {
      final result = await showVaultOperationProgress<VaultFileResult>(
        context: context,
        title: 'Adding File ${completed + failed + cancelled + 1}/${filePaths.length}',
        operation: (onProgress, taskId) async {
          _currentTaskId = taskId;
          
          return await _vaultOps.addFileToVault(
            sourcePath: path,
            type: _detectFileType(path),
            vaultPath: '/path/to/vault/${DateTime.now().millisecondsSinceEpoch}.enc',
            taskId: taskId,
            compress: true,
            encrypt: true,
            onProgress: onProgress,
          );
        },
        onCancel: () async {
          if (_currentTaskId != null) {
            await _vaultOps.cancelOperation(_currentTaskId!);
          }
        },
      );

      if (result != null) {
        if (result.success) {
          completed++;
        } else if (result.cancelled) {
          cancelled++;
          break; // Stop processing remaining files
        } else {
          failed++;
        }
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Batch complete: $completed succeeded, $failed failed, $cancelled cancelled',
        ),
        backgroundColor: cancelled > 0 ? Colors.orange : Colors.green,
      ),
    );
  }

  /// Example: Check if FFmpeg is available before compression
  Future<void> _checkFFmpegAvailability() async {
    final isAvailable = await ImprovedCompressionService.instance.isFFmpegAvailable();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('FFmpeg Status'),
        content: Text(
          isAvailable
              ? 'FFmpeg is available. Video compression is enabled.'
              : 'FFmpeg is not available. Video compression will be skipped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  VaultedFileType _detectFileType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      return VaultedFileType.video;
    } else if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
      return VaultedFileType.image;
    }
    return VaultedFileType.other;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Improved Vault Operations'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Features:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('✓ Compression runs in isolate (non-blocking)'),
            const Text('✓ Real-time progress tracking'),
            const Text('✓ Cancellation support'),
            const Text('✓ Automatic rollback on cancel/error'),
            const Text('✓ FFmpeg progress parsing'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _addFileToVault('/path/to/video.mp4'),
              icon: const Icon(Icons.add),
              label: const Text('Add Single File'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _addMultipleFiles([
                '/path/to/video1.mp4',
                '/path/to/video2.mp4',
                '/path/to/video3.mp4',
              ]),
              icon: const Icon(Icons.add_to_photos),
              label: const Text('Add Multiple Files'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _checkFFmpegAvailability,
              icon: const Icon(Icons.info),
              label: const Text('Check FFmpeg Status'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'How it works:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Compression runs in background isolate\n'
              '2. FFmpeg stderr is parsed for progress\n'
              '3. User can cancel at any time\n'
              '4. On cancel, all temp files are deleted\n'
              '5. Encryption uses streaming for large files\n'
              '6. Progress updates in real-time',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
