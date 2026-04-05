import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Improved compression service with isolate support, progress tracking, and cancellation
class ImprovedCompressionService {
  ImprovedCompressionService._();
  static final ImprovedCompressionService instance = ImprovedCompressionService._();

  final Map<String, CompressionTask> _activeTasks = {};

  /// Compress video with progress tracking and cancellation support
  Future<CompressionResult?> compressVideo({
    required String sourcePath,
    required String taskId,
    VideoCompressionQuality quality = VideoCompressionQuality.medium,
    Function(double progress)? onProgress,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        debugPrint('[ImprovedCompression] Source file does not exist: $sourcePath');
        return null;
      }

      final originalSize = await sourceFile.length();
      
      // Skip compression for very small files (< 5MB)
      if (originalSize < 5 * 1024 * 1024) {
        debugPrint('[ImprovedCompression] File too small to compress, skipping');
        return CompressionResult(
          compressedPath: sourcePath,
          originalSize: originalSize,
          compressedSize: originalSize,
          compressionRatio: 0,
          skipped: true,
        );
      }

      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Create receive port for isolate communication
      final receivePort = ReceivePort();
      final completer = Completer<CompressionResult?>();

      // Create task for tracking
      final task = CompressionTask(
        taskId: taskId,
        sourcePath: sourcePath,
        outputPath: outputPath,
        receivePort: receivePort,
        completer: completer,
      );
      _activeTasks[taskId] = task;

      // Spawn isolate
      final isolate = await Isolate.spawn(
        _videoCompressionIsolate,
        _VideoCompressionParams(
          sourcePath: sourcePath,
          outputPath: outputPath,
          quality: quality,
          sendPort: receivePort.sendPort,
        ),
      );

      task.isolate = isolate;

      // Listen to isolate messages
      receivePort.listen((message) {
        if (message is Map<String, dynamic>) {
          if (message['type'] == 'progress') {
            final progress = message['progress'] as double;
            onProgress?.call(progress);
          } else if (message['type'] == 'complete') {
            final result = CompressionResult(
              compressedPath: message['outputPath'] as String,
              originalSize: message['originalSize'] as int,
              compressedSize: message['compressedSize'] as int,
              compressionRatio: message['compressionRatio'] as double,
            );
            completer.complete(result);
            _cleanupTask(taskId);
          } else if (message['type'] == 'error') {
            completer.completeError(message['error'] as String);
            _cleanupTask(taskId);
          } else if (message['type'] == 'cancelled') {
            completer.complete(null);
            _cleanupTask(taskId);
          }
        }
      });

      return await completer.future;
    } catch (e) {
      debugPrint('[ImprovedCompression] Error compressing video: $e');
      _cleanupTask(taskId);
      return null;
    }
  }

  /// Cancel compression and rollback changes
  Future<bool> cancelCompression(String taskId) async {
    final task = _activeTasks[taskId];
    if (task == null) {
      debugPrint('[ImprovedCompression] Task not found: $taskId');
      return false;
    }

    try {
      debugPrint('[ImprovedCompression] Cancelling task: $taskId');
      
      // Kill the isolate
      task.isolate?.kill(priority: Isolate.immediate);
      
      // Delete partial output file
      final outputFile = File(task.outputPath);
      if (await outputFile.exists()) {
        await outputFile.delete();
        debugPrint('[ImprovedCompression] Deleted partial output: ${task.outputPath}');
      }

      // Complete with null to indicate cancellation
      if (!task.completer.isCompleted) {
        task.completer.complete(null);
      }

      _cleanupTask(taskId);
      return true;
    } catch (e) {
      debugPrint('[ImprovedCompression] Error cancelling task: $e');
      return false;
    }
  }

  /// Cleanup task resources
  void _cleanupTask(String taskId) {
    final task = _activeTasks.remove(taskId);
    if (task != null) {
      task.receivePort.close();
      task.isolate?.kill(priority: Isolate.immediate);
    }
  }

  /// Check if FFmpeg is available
  Future<bool> isFFmpegAvailable() async {
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Get all active compression tasks
  List<String> getActiveTasks() {
    return _activeTasks.keys.toList();
  }
}

/// Isolate function for video compression
void _videoCompressionIsolate(_VideoCompressionParams params) async {
  Process? process;
  
  try {
    final sourceFile = File(params.sourcePath);
    final originalSize = await sourceFile.length();

    // Get video duration for progress calculation
    final durationResult = await Process.run('ffprobe', [
      '-v',
      'error',
      '-show_entries',
      'format=duration',
      '-of',
      'default=noprint_wrappers=1:nokey=1',
      params.sourcePath,
    ]);

    double? totalDuration;
    if (durationResult.exitCode == 0) {
      totalDuration = double.tryParse(durationResult.stdout.toString().trim());
    }

    // Build FFmpeg command based on quality
    final args = _buildFFmpegArgs(params.sourcePath, params.outputPath, params.quality);

    // Start FFmpeg process
    process = await Process.start('ffmpeg', args);

    // Monitor stderr for progress
    final stderrSubscription = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      // Parse FFmpeg progress: "frame= 123 fps=30 time=00:00:04.10"
      if (totalDuration != null && line.contains('time=')) {
        final timeMatch = RegExp(r'time=(\d+):(\d+):(\d+\.\d+)').firstMatch(line);
        if (timeMatch != null) {
          final hours = int.parse(timeMatch.group(1)!);
          final minutes = int.parse(timeMatch.group(2)!);
          final seconds = double.parse(timeMatch.group(3)!);
          final currentTime = hours * 3600 + minutes * 60 + seconds;
          final progress = (currentTime / totalDuration).clamp(0.0, 1.0);
          
          params.sendPort.send({
            'type': 'progress',
            'progress': progress,
          });
        }
      }
    });

    final exitCode = await process.exitCode;
    await stderrSubscription.cancel();

    if (exitCode == 0) {
      final outputFile = File(params.outputPath);
      if (await outputFile.exists()) {
        final compressedSize = await outputFile.length();
        final compressionRatio = ((originalSize - compressedSize) / originalSize * 100);

        params.sendPort.send({
          'type': 'complete',
          'outputPath': params.outputPath,
          'originalSize': originalSize,
          'compressedSize': compressedSize,
          'compressionRatio': compressionRatio,
        });
      } else {
        params.sendPort.send({
          'type': 'error',
          'error': 'Output file not created',
        });
      }
    } else {
      params.sendPort.send({
        'type': 'error',
        'error': 'FFmpeg exited with code $exitCode',
      });
    }
  } catch (e) {
    // Check if it was a cancellation
    if (e.toString().contains('killed') || e.toString().contains('cancelled')) {
      params.sendPort.send({'type': 'cancelled'});
    } else {
      params.sendPort.send({
        'type': 'error',
        'error': e.toString(),
      });
    }
  } finally {
    process?.kill();
  }
}

/// Build FFmpeg arguments based on quality
List<String> _buildFFmpegArgs(String input, String output, VideoCompressionQuality quality) {
  final baseArgs = ['-i', input];
  
  switch (quality) {
    case VideoCompressionQuality.high:
      return [
        ...baseArgs,
        '-vcodec', 'libx264',
        '-preset', 'medium',
        '-crf', '18',
        '-acodec', 'aac',
        '-b:a', '192k',
        '-movflags', '+faststart',
        '-y',
        output,
      ];
    case VideoCompressionQuality.medium:
      return [
        ...baseArgs,
        '-vcodec', 'libx264',
        '-preset', 'fast',
        '-crf', '23',
        '-acodec', 'aac',
        '-b:a', '128k',
        '-movflags', '+faststart',
        '-y',
        output,
      ];
    case VideoCompressionQuality.low:
      return [
        ...baseArgs,
        '-vcodec', 'libx264',
        '-preset', 'veryfast',
        '-crf', '28',
        '-acodec', 'aac',
        '-b:a', '96k',
        '-movflags', '+faststart',
        '-y',
        output,
      ];
  }
}

/// Compression task tracking
class CompressionTask {
  final String taskId;
  final String sourcePath;
  final String outputPath;
  final ReceivePort receivePort;
  final Completer<CompressionResult?> completer;
  Isolate? isolate;

  CompressionTask({
    required this.taskId,
    required this.sourcePath,
    required this.outputPath,
    required this.receivePort,
    required this.completer,
    this.isolate,
  });
}

/// Parameters for video compression isolate
class _VideoCompressionParams {
  final String sourcePath;
  final String outputPath;
  final VideoCompressionQuality quality;
  final SendPort sendPort;

  const _VideoCompressionParams({
    required this.sourcePath,
    required this.outputPath,
    required this.quality,
    required this.sendPort,
  });
}

/// Video compression quality levels
enum VideoCompressionQuality {
  high,   // CRF 18, slower but better quality
  medium, // CRF 23, balanced
  low,    // CRF 28, faster but lower quality
}

/// Result of compression operation
class CompressionResult {
  final String compressedPath;
  final int originalSize;
  final int compressedSize;
  final double compressionRatio;
  final bool skipped;

  CompressionResult({
    required this.compressedPath,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
    this.skipped = false,
  });

  String get formattedOriginalSize => _formatBytes(originalSize);
  String get formattedCompressedSize => _formatBytes(compressedSize);
  String get formattedRatio => '${compressionRatio.toStringAsFixed(1)}%';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
