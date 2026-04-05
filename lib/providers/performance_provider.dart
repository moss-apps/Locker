import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/frame_rate_optimizer.dart';

/// Provider for performance mode
final performanceModeProvider =
    NotifierProvider<PerformanceModeNotifier, PerformanceMode>(() {
  return PerformanceModeNotifier();
});

/// Provider for performance overlay visibility (debug only)
final performanceOverlayProvider = StateProvider<bool>((ref) => false);

/// Notifier for managing performance mode
class PerformanceModeNotifier extends Notifier<PerformanceMode> {
  static const String _key = 'performance_mode';
  final FrameRateOptimizer _optimizer = FrameRateOptimizer();

  @override
  PerformanceMode build() {
    _loadPerformanceMode();
    return PerformanceMode.balanced;
  }

  Future<void> _loadPerformanceMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_key) ?? 1; // Default to balanced
    state = PerformanceMode.values[modeIndex];
    _optimizer.setPerformanceMode(state);
  }

  Future<void> setMode(PerformanceMode mode) async {
    state = mode;
    _optimizer.setPerformanceMode(mode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }

  String getModeDescription(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.highPerformance:
        return 'Prioritizes smooth animations and high frame rates';
      case PerformanceMode.balanced:
        return 'Balances performance and visual quality';
      case PerformanceMode.quality:
        return 'Prioritizes visual quality over performance';
    }
  }

  String getModeName(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.highPerformance:
        return 'High Performance';
      case PerformanceMode.balanced:
        return 'Balanced';
      case PerformanceMode.quality:
        return 'Quality';
    }
  }
}
