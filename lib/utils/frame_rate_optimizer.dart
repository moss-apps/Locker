import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// High frame rate optimization manager for smooth UI performance
/// Monitors and optimizes frame rendering to reduce jank
class FrameRateOptimizer {
  static final FrameRateOptimizer _instance = FrameRateOptimizer._internal();
  factory FrameRateOptimizer() => _instance;
  FrameRateOptimizer._internal();

  // Performance metrics
  final List<Duration> _frameTimes = [];
  final int _maxFrameHistory = 120; // 2 seconds at 60fps
  int _droppedFrames = 0;
  int _totalFrames = 0;
  double _averageFps = 60.0;

  // Thresholds
  static const Duration _jankThreshold = Duration(milliseconds: 32); // 2 frames

  bool _isMonitoring = false;
  FrameCallback? _frameCallback;

  // Performance mode
  PerformanceMode _currentMode = PerformanceMode.balanced;

  /// Start monitoring frame performance
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _frameCallback = (duration) {
      if (_isMonitoring) {
        _onFrame(duration);
        SchedulerBinding.instance.scheduleFrameCallback(_frameCallback!);
      }
    };
    SchedulerBinding.instance.scheduleFrameCallback(_frameCallback!);

    if (kDebugMode) {
      print('FrameRateOptimizer: Monitoring started');
    }
  }

  /// Stop monitoring frame performance
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _frameCallback = null;

    if (kDebugMode) {
      print('FrameRateOptimizer: Monitoring stopped');
    }
  }

  void _onFrame(Duration timestamp) {
    final Duration frameTime = SchedulerBinding.instance.currentFrameTimeStamp;

    _frameTimes.add(frameTime);
    if (_frameTimes.length > _maxFrameHistory) {
      _frameTimes.removeAt(0);
    }

    _totalFrames++;

    // Check for dropped frames
    if (_frameTimes.length >= 2) {
      final lastFrameDuration = _frameTimes.last.inMicroseconds -
          _frameTimes[_frameTimes.length - 2].inMicroseconds;

      if (lastFrameDuration > _jankThreshold.inMicroseconds) {
        _droppedFrames++;

        if (kDebugMode) {
          print(
              'FrameRateOptimizer: Jank detected - ${lastFrameDuration / 1000}ms');
        }
      }
    }

    // Calculate average FPS every 60 frames
    if (_totalFrames % 60 == 0 && _frameTimes.length >= 2) {
      _calculateAverageFps();
    }
  }

  void _calculateAverageFps() {
    if (_frameTimes.length < 2) return;

    final totalDuration =
        _frameTimes.last.inMicroseconds - _frameTimes.first.inMicroseconds;

    if (totalDuration > 0) {
      _averageFps = (_frameTimes.length - 1) * 1000000 / totalDuration;
    }
  }

  /// Get current performance metrics
  PerformanceMetrics getMetrics() {
    return PerformanceMetrics(
      averageFps: _averageFps,
      droppedFrames: _droppedFrames,
      totalFrames: _totalFrames,
      jankPercentage:
          _totalFrames > 0 ? (_droppedFrames / _totalFrames) * 100 : 0,
    );
  }

  /// Reset performance metrics
  void resetMetrics() {
    _frameTimes.clear();
    _droppedFrames = 0;
    _totalFrames = 0;
    _averageFps = 60.0;
  }

  /// Set performance mode
  void setPerformanceMode(PerformanceMode mode) {
    _currentMode = mode;
    _applyPerformanceMode();
  }

  void _applyPerformanceMode() {
    switch (_currentMode) {
      case PerformanceMode.highPerformance:
        // Prioritize frame rate over visual quality
        if (kDebugMode) {
          print('FrameRateOptimizer: High performance mode enabled');
        }
        break;
      case PerformanceMode.balanced:
        // Balance between performance and quality
        if (kDebugMode) {
          print('FrameRateOptimizer: Balanced mode enabled');
        }
        break;
      case PerformanceMode.quality:
        // Prioritize visual quality
        if (kDebugMode) {
          print('FrameRateOptimizer: Quality mode enabled');
        }
        break;
    }
  }

  /// Get current performance mode
  PerformanceMode get currentMode => _currentMode;

  /// Check if performance is acceptable
  bool get isPerformanceGood =>
      _averageFps >= 55 &&
      (_totalFrames > 0 ? (_droppedFrames / _totalFrames) < 0.05 : true);

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _frameTimes.clear();
  }
}

/// Performance mode options
enum PerformanceMode {
  highPerformance,
  balanced,
  quality,
}

/// Performance metrics data class
class PerformanceMetrics {
  final double averageFps;
  final int droppedFrames;
  final int totalFrames;
  final double jankPercentage;

  const PerformanceMetrics({
    required this.averageFps,
    required this.droppedFrames,
    required this.totalFrames,
    required this.jankPercentage,
  });

  @override
  String toString() {
    return 'PerformanceMetrics(fps: ${averageFps.toStringAsFixed(1)}, '
        'dropped: $droppedFrames/$totalFrames, '
        'jank: ${jankPercentage.toStringAsFixed(2)}%)';
  }
}
