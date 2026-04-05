import 'package:flutter/material.dart';

/// Dialog for selecting compression options
class CompressionOptionsDialog extends StatefulWidget {
  final bool isVideo;
  
  const CompressionOptionsDialog({
    super.key,
    this.isVideo = false,
  });

  @override
  State<CompressionOptionsDialog> createState() => _CompressionOptionsDialogState();
}

class _CompressionOptionsDialogState extends State<CompressionOptionsDialog> {
  CompressionOption _selectedOption = CompressionOption.none;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Compression Options'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.isVideo 
              ? 'Compress video before importing?'
              : 'Compress image before importing?',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 16),
          _buildOption(
            CompressionOption.none,
            'No Compression',
            'Keep original quality',
          ),
          _buildOption(
            CompressionOption.low,
            'Low Compression',
            widget.isVideo ? 'Good quality, smaller size' : 'Quality: 85%',
          ),
          _buildOption(
            CompressionOption.medium,
            'Medium Compression',
            widget.isVideo ? 'Balanced quality and size' : 'Quality: 70%',
          ),
          _buildOption(
            CompressionOption.high,
            'High Compression',
            widget.isVideo ? 'Lower quality, smallest size' : 'Quality: 50%',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedOption),
          child: Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildOption(CompressionOption option, String title, String subtitle) {
    return RadioListTile<CompressionOption>(
      value: option,
      groupValue: _selectedOption,
      onChanged: (value) {
        setState(() {
          _selectedOption = value!;
        });
      },
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
      dense: true,
    );
  }
}

/// Compression option levels
enum CompressionOption {
  none,
  low,
  high,
  medium,
}

/// Extension to get quality values
extension CompressionOptionExtension on CompressionOption {
  int get imageQuality {
    switch (this) {
      case CompressionOption.none:
        return 100;
      case CompressionOption.low:
        return 85;
      case CompressionOption.medium:
        return 70;
      case CompressionOption.high:
        return 50;
    }
  }

  String get videoQualityName {
    switch (this) {
      case CompressionOption.none:
        return 'original';
      case CompressionOption.low:
        return 'high';
      case CompressionOption.medium:
        return 'medium';
      case CompressionOption.high:
        return 'low';
    }
  }
}
