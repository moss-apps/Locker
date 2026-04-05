import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

/// Service for compressing photos and videos
class MediaCompressionService {
  MediaCompressionService._();
  static final MediaCompressionService instance = MediaCompressionService._();

  /// Compression quality levels
  static const int qualityHigh = 85;
  static const int qualityMedium = 70;
  static const int qualityLow = 50;

  /// Video compression quality levels
  static const VideoQuality videoQualityHigh = VideoQuality.HighestQuality;
  static const VideoQuality videoQualityMedium = VideoQuality.DefaultQuality;
  static const VideoQuality videoQualityLow = VideoQuality.LowQuality;

  /// Compress an image file
  /// Returns the path to the compressed file, or null if compression failed
  Future<CompressionResult?> compressImage({
    required String sourcePath,
    int quality = qualityMedium,
    int? maxWidth,
    int? maxHeight,
    bool keepExif = true,
  }) async {
    try {
      debugPrint('[Compression] Compressing image: $sourcePath');
      
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        debugPrint('[Compression] Source file does not exist');
        return null;
      }

      final originalSize = await sourceFile.length();
      
      // Create temp directory for compressed file
      final tempDir = await getTemporaryDirectory();
      final fileName = sourcePath.split('/').last;
      final targetPath = '${tempDir.path}/compressed_$fileName';

      // Compress using flutter_image_compress
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: quality,
        minWidth: maxWidth ?? 1920,
        minHeight: maxHeight ?? 1920,
        keepExif: keepExif,
      );

      if (result == null) {
        debugPrint('[Compression] Image compression failed');
        return null;
      }

      final compressedSize = await result.length();
      final compressionRatio = ((originalSize - compressedSize) / originalSize * 100);

      debugPrint('[Compression] Image compressed: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)} (${compressionRatio.toStringAsFixed(1)}% reduction)');

      return CompressionResult(
        compressedPath: result.path,
        originalSize: originalSize,
        compressedSize: compressedSize,
        compressionRatio: compressionRatio,
      );
    } catch (e) {
      debugPrint('[Compression] Error compressing image: $e');
      return null;
    }
  }

  /// Compress an image with custom dimensions
  Future<CompressionResult?> compressImageWithDimensions({
    required String sourcePath,
    required int targetWidth,
    required int targetHeight,
    int quality = qualityMedium,
  }) async {
    try {
      debugPrint('[Compression] Compressing image with dimensions: ${targetWidth}x$targetHeight');
      
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return null;
      }

      final originalSize = await sourceFile.length();
      
      // Read and decode image
      final bytes = await sourceFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        debugPrint('[Compression] Failed to decode image');
        return null;
      }

      // Resize image maintaining aspect ratio
      final resized = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode with quality
      final List<int> compressed;
      final ext = sourcePath.split('.').last.toLowerCase();
      
      if (ext == 'png') {
        compressed = img.encodePng(resized, level: 6);
      } else {
        compressed = img.encodeJpg(resized, quality: quality);
      }

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName = sourcePath.split('/').last;
      final targetPath = '${tempDir.path}/resized_$fileName';
      final targetFile = File(targetPath);
      await targetFile.writeAsBytes(compressed);

      final compressedSize = compressed.length;
      final compressionRatio = ((originalSize - compressedSize) / originalSize * 100);

      debugPrint('[Compression] Image resized and compressed: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)}');

      return CompressionResult(
        compressedPath: targetPath,
        originalSize: originalSize,
        compressedSize: compressedSize,
        compressionRatio: compressionRatio,
      );
    } catch (e) {
      debugPrint('[Compression] Error compressing image with dimensions: $e');
      return null;
    }
  }

  /// Compress a video file
  /// Returns the path to the compressed file, or null if compression failed
  Future<CompressionResult?> compressVideo({
    required String sourcePath,
    VideoQuality quality = videoQualityMedium,
    bool deleteOrigin = false,
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('[Compression] Compressing video: $sourcePath');
      
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        debugPrint('[Compression] Source file does not exist');
        return null;
      }

      final originalSize = await sourceFile.length();

      // Subscribe to compression progress
      VideoCompress.compressProgress$.subscribe((progress) {
        onProgress?.call(progress);
      });

      // Compress video
      final info = await VideoCompress.compressVideo(
        sourcePath,
        quality: quality,
        deleteOrigin: deleteOrigin,
        includeAudio: true,
      );

      if (info == null || info.file == null) {
        debugPrint('[Compression] Video compression failed');
        return null;
      }

      final compressedSize = await info.file!.length();
      final compressionRatio = ((originalSize - compressedSize) / originalSize * 100);

      debugPrint('[Compression] Video compressed: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)} (${compressionRatio.toStringAsFixed(1)}% reduction)');

      return CompressionResult(
        compressedPath: info.file!.path,
        originalSize: originalSize,
        compressedSize: compressedSize,
        compressionRatio: compressionRatio,
        duration: info.duration,
      );
    } catch (e) {
      debugPrint('[Compression] Error compressing video: $e');
      return null;
    }
  }

  /// Get video thumbnail
  Future<File?> getVideoThumbnail({
    required String videoPath,
    int quality = 50,
  }) async {
    try {
      final thumbnail = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: quality,
      );
      return thumbnail;
    } catch (e) {
      debugPrint('[Compression] Error getting video thumbnail: $e');
      return null;
    }
  }

  /// Cancel ongoing video compression
  Future<void> cancelVideoCompression() async {
    try {
      await VideoCompress.cancelCompression();
    } catch (e) {
      debugPrint('[Compression] Error canceling compression: $e');
    }
  }

  /// Delete all cached compressed files
  Future<void> clearCache() async {
    try {
      await VideoCompress.deleteAllCache();
      debugPrint('[Compression] Cache cleared');
    } catch (e) {
      debugPrint('[Compression] Error clearing cache: $e');
    }
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Result of a compression operation
class CompressionResult {
  final String compressedPath;
  final int originalSize;
  final int compressedSize;
  final double compressionRatio;
  final double? duration;

  CompressionResult({
    required this.compressedPath,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
    this.duration,
  });

  String get formattedOriginalSize => _formatBytes(originalSize);
  String get formattedCompressedSize => _formatBytes(compressedSize);
  String get formattedRatio => '${compressionRatio.toStringAsFixed(1)}%';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
