import 'package:flutter/material.dart';
import '../services/improved_vault_operations.dart';

/// Dialog showing vault operation progress with cancellation support
class VaultOperationProgressDialog extends StatefulWidget {
  final String title;
  final VoidCallback onCancel;

  const VaultOperationProgressDialog({
    Key? key,
    required this.title,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<VaultOperationProgressDialog> createState() => _VaultOperationProgressDialogState();
}

class _VaultOperationProgressDialogState extends State<VaultOperationProgressDialog> {
  VaultOperationProgress? _currentProgress;
  bool _cancelling = false;

  void updateProgress(VaultOperationProgress progress) {
    if (mounted) {
      setState(() {
        _currentProgress = progress;
      });
    }
  }

  void _handleCancel() {
    setState(() {
      _cancelling = true;
    });
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing by back button
      child: AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_cancelling)
              const Text(
                'Cancelling and cleaning up...',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              )
            else if (_currentProgress != null) ...[
              Text(
                _currentProgress!.message,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _currentProgress!.progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getStageColor(_currentProgress!.stage),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_currentProgress!.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              _buildStageIndicator(_currentProgress!.stage),
            ] else ...[
              const Text('Preparing...'),
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
        actions: [
          if (!_cancelling)
            TextButton(
              onPressed: _handleCancel,
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStageIndicator(VaultOperationStage stage) {
    return Row(
      children: [
        _buildStageChip('Compress', stage == VaultOperationStage.compressing),
        const SizedBox(width: 8),
        _buildStageChip('Encrypt', stage == VaultOperationStage.encrypting),
        const SizedBox(width: 8),
        _buildStageChip('Complete', stage == VaultOperationStage.complete),
      ],
    );
  }

  Widget _buildStageChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: active ? Colors.white : Colors.grey[600],
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Color _getStageColor(VaultOperationStage stage) {
    switch (stage) {
      case VaultOperationStage.compressing:
        return Colors.orange;
      case VaultOperationStage.encrypting:
        return Colors.blue;
      case VaultOperationStage.copying:
        return Colors.green;
      case VaultOperationStage.complete:
        return Colors.green;
    }
  }
}

/// Show vault operation progress dialog
Future<T?> showVaultOperationProgress<T>({
  required BuildContext context,
  required String title,
  required Future<T> Function(
    Function(VaultOperationProgress) onProgress,
    String taskId,
  ) operation,
  required VoidCallback onCancel,
}) async {
  final dialogKey = GlobalKey<_VaultOperationProgressDialogState>();
  
  // Show dialog
  final dialogFuture = showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (context) => VaultOperationProgressDialog(
      key: dialogKey,
      title: title,
      onCancel: onCancel,
    ),
  );

  // Start operation
  final taskId = DateTime.now().millisecondsSinceEpoch.toString();
  
  try {
    final result = await operation(
      (progress) {
        dialogKey.currentState?.updateProgress(progress);
      },
      taskId,
    );

    // Close dialog
    if (context.mounted) {
      Navigator.of(context).pop(result);
    }

    return result;
  } catch (e) {
    // Close dialog on error
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    rethrow;
  }
}
