import 'package:flutter/material.dart';
import '../services/media_compression_service.dart';
import '../utils/compression_helper.dart';
import '../widgets/compression_options_dialog.dart';

/// Example showing how to use compression features
class CompressionUsageExample extends StatefulWidget {
  const CompressionUsageExample({super.key});

  @override
  State<CompressionUsageExample> createState() => _CompressionUsageExampleState();
}

class _CompressionUsageExampleState extends State<CompressionUsageExample> {
  String _statusMessage = '';
  double _compressionProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compression Examples'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Media Compression Options',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            
            // Status message
            if (_statusMessage.isNotEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(_statusMessage),
                ),
              ),
            
            // Progress indicator
            if (_compressionProgress > 0)
              LinearProgressIndicator(value: _compressionProgress),
            
            SizedBox(height: 24),
            
            // Example buttons
            ElevatedButton(
              onPressed: _exampleCompressImage,
              child: Text('Example: Compress Image'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _exampleCompressVideo,
              child: Text('Example: Compress Video'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _exampleShowCompressionDialog,
              child: Text('Example: Show Compression Dialog'),
            ),
            SizedBox(height: 24),
            
            // Usage instructions
            Expanded(
              child: SingleChildScrollView(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usage Instructions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildUsageSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Basic Image Compression:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          '''
final result = await MediaCompressionService.instance.compressImage(
  sourcePath: '/path/to/image.jpg',
  quality: 70,  // 0-100
  maxWidth: 1920,
  maxHeight: 1920,
);

if (result != null) {
  print('Compressed: \${result.formattedOriginalSize} → \${result.formattedCompressedSize}');
  print('Saved: \${result.formattedRatio}');
  // Use result.compressedPath
}
''',
          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        SizedBox(height: 16),
        
        Text(
          '2. Basic Video Compression:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          '''
final result = await MediaCompressionService.instance.compressVideo(
  sourcePath: '/path/to/video.mp4',
  quality: VideoQuality.DefaultQuality,
  onProgress: (progress) {
    print('Progress: \${progress.toStringAsFixed(1)}%');
  },
);

if (result != null) {
  print('Compressed: \${result.formattedOriginalSize} → \${result.formattedCompressedSize}');
  // Use result.compressedPath
}
''',
          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        SizedBox(height: 16),
        
        Text(
          '3. Using Compression Dialog:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          '''
// Show dialog to user
final option = await CompressionHelper.showCompressionDialog(
  context,
  isVideo: false,
);

if (option != null) {
  // Compress based on user selection
  final compressedPath = await CompressionHelper.compressImageIfNeeded(
    sourcePath: imagePath,
    option: option,
    onStatusUpdate: (message) => print(message),
  );
  
  // Use compressedPath for import
}
''',
          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        SizedBox(height: 16),
        
        Text(
          '4. Batch Compression:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          '''
final compressedPaths = await CompressionHelper.compressImagesIfNeeded(
  sourcePaths: ['/path/1.jpg', '/path/2.jpg'],
  option: CompressionOption.medium,
  onProgress: (current, total) {
    print('Compressing \$current/\$total');
  },
);
''',
          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        SizedBox(height: 16),
        
        Text(
          'Quality Levels:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text('• None: Original quality (100%)'),
        Text('• Low: High quality (85%)'),
        Text('• Medium: Balanced (70%)'),
        Text('• High: Maximum compression (50%)'),
      ],
    );
  }

  Future<void> _exampleCompressImage() async {
    setState(() {
      _statusMessage = 'This would compress an image file...';
      _compressionProgress = 0.0;
    });

    // In real usage, you would have an actual image path
    // final result = await MediaCompressionService.instance.compressImage(
    //   sourcePath: imagePath,
    //   quality: 70,
    // );
    
    await Future.delayed(Duration(seconds: 2));
    
    setState(() {
      _statusMessage = 'Example: Image compressed from 5.2 MB → 1.8 MB (65% saved)';
      _compressionProgress = 1.0;
    });
  }

  Future<void> _exampleCompressVideo() async {
    setState(() {
      _statusMessage = 'This would compress a video file...';
      _compressionProgress = 0.0;
    });

    // Simulate progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(Duration(milliseconds: 200));
      setState(() {
        _compressionProgress = i / 100;
        _statusMessage = 'Compressing video: ${i}%';
      });
    }
    
    setState(() {
      _statusMessage = 'Example: Video compressed from 45.3 MB → 12.7 MB (72% saved)';
    });
  }

  Future<void> _exampleShowCompressionDialog() async {
    final option = await CompressionHelper.showCompressionDialog(
      context,
      isVideo: false,
    );

    if (option != null) {
      setState(() {
        _statusMessage = 'Selected: ${option.name} (Quality: ${option.imageQuality}%)';
        _compressionProgress = 0.0;
      });
    }
  }
}
