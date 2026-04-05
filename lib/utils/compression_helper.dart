import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import '../services/media_compression_service.dart';
import '../widgets/compression_options_dialog.dart';

/// Helper class for handling media compression in import flows
class CompressionHelper {
  /// Show compression options dialog and return selected option
  static Future<CompressionOption?> showCompressionDialog(
    BuildContext context, {
    required bool isVideo,
  }) async {
    return await showDialog<CompressionOption>(
      context: context,
      builder: (context) => CompressionOptionsDialog(isVideo: isVideo),
    );
  }

  /// Compress image file based on selected option
  static Future<String?> compressImageIfNeeded({
    required String sourcePath,
    required CompressionOption option,
    Function(String message)? onStatusUpdate,
  }) async {
    if (option == CompressionOption.none) {
      return sourcePath;
    }

    onStatusUpdate?.call('Compressing image...');

    final result = await MediaCompressionService.instance.compressImage(
      sourcePath: sourcePath,
      quality: option.imageQuality,
    );

    if (result != null) {
      onStatusUpdate?.call(
        'Compressed: ${result.formattedOriginalSize} → ${result.formattedCompressedSize} (${result.formattedRatio} saved)',
      );
      return result.compressedPath;
    }

    return sourcePath;
  }

  /// Compress video file based on selected option
  static Future<String?> compressVideoIfNeeded({
    required String sourcePath,
    required CompressionOption option,
    Function(String message)? onStatusUpdate,
    Function(double progress)? onProgress,
  }) async {
    if (option == CompressionOption.none) {
      return sourcePath;
    }

    onStatusUpdate?.call('Compressing video...');

    VideoQuality quality;
    switch (option) {
      case CompressionOption.low:
        quality = VideoQuality.HighestQuality;
        break;
      case CompressionOption.medium:
        quality = VideoQuality.DefaultQuality;
        break;
      case CompressionOption.high:
        quality = VideoQuality.LowQuality;
        break;
      default:
        quality = VideoQuality.DefaultQuality;
    }

    final result = await MediaCompressionService.instance.compressVideo(
      sourcePath: sourcePath,
      quality: quality,
      onProgress: onProgress,
    );

    if (result != null) {
      onStatusUpdate?.call(
        'Compressed: ${result.formattedOriginalSize} → ${result.formattedCompressedSize} (${result.formattedRatio} saved)',
      );
      return result.compressedPath;
    }

    return sourcePath;
  }

  /// Compress multiple images
  static Future<List<String>> compressImagesIfNeeded({
    required List<String> sourcePaths,
    required CompressionOption option,
    Function(int current, int total)? onProgress,
    Function(String message)? onStatusUpdate,
  }) async {
    if (option == CompressionOption.none) {
      return sourcePaths;
    }

    final compressedPaths = <String>[];
    
    for (int i = 0; i < sourcePaths.length; i++) {
      onStatusUpdate?.call('Compressing image ${i + 1}/${sourcePaths.length}...');
      onProgress?.call(i + 1, sourcePaths.length);

      final compressed = await compressImageIfNeeded(
        sourcePath: sourcePaths[i],
        option: option,
      );

      compressedPaths.add(compressed ?? sourcePaths[i]);
    }

    return compressedPaths;
  }

  /// Compress multiple videos
  static Future<List<String>> compressVideosIfNeeded({
    required List<String> sourcePaths,
    required CompressionOption option,
    Function(int current, int total)? onProgress,
    Function(String message)? onStatusUpdate,
  }) async {
    if (option == CompressionOption.none) {
      return sourcePaths;
    }

    final compressedPaths = <String>[];
    
    for (int i = 0; i < sourcePaths.length; i++) {
      onStatusUpdate?.call('Compressing video ${i + 1}/${sourcePaths.length}...');

      final compressed = await compressVideoIfNeeded(
        sourcePath: sourcePaths[i],
        option: option,
        onProgress: (progress) {
          onProgress?.call(i, sourcePaths.length);
        },
      );

      compressedPaths.add(compressed ?? sourcePaths[i]);
    }

    return compressedPaths;
  }

  /// Show compression progress dialog
  static Future<T?> showCompressionProgress<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    String title = 'Compressing...',
  }) async {
    return await showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Please wait...'),
            ],
          ),
        ),
      ),
    );
  }

  /// Clean up temporary compressed files
  static Future<void> cleanupTempFiles(List<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists() && path.contains('compressed_')) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('[CompressionHelper] Error deleting temp file: $e');
      }
    }
  }
}
