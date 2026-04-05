import 'package:flutter/material.dart';
import 'dart:io';

/// Optimized image widget with caching and performance improvements
class OptimizedImageWidget extends StatelessWidget {
  final File imageFile;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableMemoryCache;
  
  const OptimizedImageWidget({
    super.key,
    required this.imageFile,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.enableMemoryCache = true,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Image.file(
        imageFile,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: width?.toInt(),
        cacheHeight: height?.toInt(),
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? 
              const Center(
                child: Icon(Icons.error_outline, color: Colors.red),
              );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: child,
          );
        },
      ),
    );
  }
}

/// Optimized thumbnail widget for grid views
class OptimizedThumbnail extends StatelessWidget {
  final File imageFile;
  final double size;
  final VoidCallback? onTap;
  
  const OptimizedThumbnail({
    super.key,
    required this.imageFile,
    this.size = 120,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            imageFile,
            fit: BoxFit.cover,
            width: size,
            height: size,
            cacheWidth: (size * 2).toInt(), // 2x for better quality
            cacheHeight: (size * 2).toInt(),
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: size,
                height: size,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        ),
      ),
    );
  }
}
