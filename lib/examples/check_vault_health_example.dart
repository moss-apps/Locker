import 'package:flutter/material.dart';
import '../utils/vault_file_checker.dart';
import '../utils/encryption_diagnostics.dart';

/// Example showing how to check vault health and fix corrupted files
class CheckVaultHealthExample extends StatefulWidget {
  const CheckVaultHealthExample({Key? key}) : super(key: key);

  @override
  State<CheckVaultHealthExample> createState() => _CheckVaultHealthExampleState();
}

class _CheckVaultHealthExampleState extends State<CheckVaultHealthExample> {
  CheckResult? _checkResult;
  bool _checking = false;

  /// Check vault health
  Future<void> _checkVaultHealth() async {
    setState(() {
      _checking = true;
    });

    try {
      final result = await VaultFileChecker.checkAllFiles();
      
      setState(() {
        _checkResult = result;
        _checking = false;
      });

      // Print detailed report to console
      await VaultFileChecker.printHealthReport();

      if (!mounted) return;

      if (result.hasCorruption) {
        _showCorruptionDialog(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All vault files are healthy!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _checking = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking vault: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show dialog with corruption details
  void _showCorruptionDialog(CheckResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Corrupted Files Detected'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.corruptedFiles.length} of ${result.totalFiles} files are corrupted.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Corrupted files:'),
              const SizedBox(height: 8),
              ...result.corruptedFiles.map((file) {
                final error = result.errors[file.id] ?? 'Unknown error';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.originalName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        error,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              const Text(
                'These files cannot be decrypted and should be removed.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeCorruptedFiles(result.corruptedFiles);
            },
            child: const Text(
              'Remove Corrupted Files',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Remove corrupted files
  Future<void> _removeCorruptedFiles(List corruptedFiles) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Removing corrupted files...'),
          ],
        ),
      ),
    );

    try {
      final removed = await VaultFileChecker.removeCorruptedFiles(corruptedFiles);

      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed $removed corrupted files'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh check
      _checkVaultHealth();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing files: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Check a specific file
  Future<void> _checkSpecificFile(String filePath) async {
    await EncryptionDiagnostics.printDiagnostics(filePath);

    final diag = await EncryptionDiagnostics.analyzeFile(filePath);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Diagnostics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDiagRow('File Size', '${diag.fileSize} bytes'),
              _buildDiagRow('Format', diag.formatDescription ?? 'Unknown'),
              _buildDiagRow('Data Length', '${diag.dataLength} bytes'),
              _buildDiagRow('Valid for CBC', diag.validForCbc ? 'Yes' : 'No'),
              if (!diag.validForCbc)
                _buildDiagRow('Remainder', '${diag.remainder} bytes', isError: true),
              if (diag.error != null)
                _buildDiagRow('Error', diag.error!, isError: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Health Check'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_checking)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Checking vault files...'),
                  ],
                ),
              )
            else if (_checkResult != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vault Health',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow('Total Files', '${_checkResult!.totalFiles}'),
                      _buildStatRow('Valid Files', '${_checkResult!.validFiles.length}'),
                      _buildStatRow(
                        'Corrupted Files',
                        '${_checkResult!.corruptedFiles.length}',
                        isError: _checkResult!.hasCorruption,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _checkResult!.healthPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _checkResult!.isHealthy ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Health: ${_checkResult!.healthPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _checkResult!.isHealthy ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_checkResult!.hasCorruption)
                ElevatedButton.icon(
                  onPressed: () => _removeCorruptedFiles(_checkResult!.corruptedFiles),
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove Corrupted Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
            ] else ...[
              const Text(
                'Check your vault for corrupted files.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will scan all encrypted files and identify any that cannot be decrypted.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checking ? null : _checkVaultHealth,
              icon: const Icon(Icons.health_and_safety),
              label: const Text('Check Vault Health'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                // Example: check a specific file
                _checkSpecificFile('/path/to/encrypted/file');
              },
              icon: const Icon(Icons.search),
              label: const Text('Check Specific File'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isError ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}
