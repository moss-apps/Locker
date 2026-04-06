import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/performance_provider.dart';
import '../utils/frame_rate_optimizer.dart';

/// Screen for configuring performance settings
class PerformanceSettingsScreen extends ConsumerWidget {
  const PerformanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceMode = ref.watch(performanceModeProvider);
    final performanceModeNotifier = ref.read(performanceModeProvider.notifier);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Performance Mode', isDarkMode),
          const SizedBox(height: 12),
          _buildPerformanceModeCard(
            context,
            PerformanceMode.highPerformance,
            performanceMode,
            performanceModeNotifier,
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildPerformanceModeCard(
            context,
            PerformanceMode.balanced,
            performanceMode,
            performanceModeNotifier,
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildPerformanceModeCard(
            context,
            PerformanceMode.quality,
            performanceMode,
            performanceModeNotifier,
            isDarkMode,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Performance Metrics', isDarkMode),
          const SizedBox(height: 12),
          _buildMetricsCard(context, isDarkMode),
          const SizedBox(height: 24),
          _buildSectionHeader('Tips', isDarkMode),
          const SizedBox(height: 12),
          _buildTipsCard(isDarkMode),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }
  
  Widget _buildPerformanceModeCard(
    BuildContext context,
    PerformanceMode mode,
    PerformanceMode currentMode,
    PerformanceModeNotifier notifier,
    bool isDarkMode,
  ) {
    final isSelected = mode == currentMode;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected 
          ? (isDarkMode ? const Color(0xFF2A2A2D) : Colors.blue[50])
          : (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => notifier.setMode(mode),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _getModeIcon(mode),
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : (isDarkMode ? Colors.white70 : Colors.black54),
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notifier.getModeName(mode),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notifier.getModeDescription(mode),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getModeIcon(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.highPerformance:
        return Icons.speed;
      case PerformanceMode.balanced:
        return Icons.balance;
      case PerformanceMode.quality:
        return Icons.high_quality;
    }
  }
  
  Widget _buildMetricsCard(BuildContext context, bool isDarkMode) {
    final optimizer = FrameRateOptimizer();
    final metrics = optimizer.getMetrics();
    
    return Card(
      elevation: 1,
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetricRow(
              'Average FPS',
              metrics.averageFps.toStringAsFixed(1),
              Icons.speed,
              isDarkMode,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Jank Percentage',
              '${metrics.jankPercentage.toStringAsFixed(2)}%',
              Icons.warning_amber,
              isDarkMode,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Dropped Frames',
              '${metrics.droppedFrames}',
              Icons.error_outline,
              isDarkMode,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                optimizer.resetMetrics();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Metrics reset')),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Metrics'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricRow(String label, String value, IconData icon, bool isDarkMode) {
    return Row(
      children: [
        Icon(icon, color: isDarkMode ? Colors.white70 : Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTipsCard(bool isDarkMode) {
    return Card(
      elevation: 1,
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTip('Close unused apps to free up memory', isDarkMode),
            const SizedBox(height: 8),
            _buildTip('Reduce animation scale in device settings', isDarkMode),
            const SizedBox(height: 8),
            _buildTip('Clear app cache periodically', isDarkMode),
            const SizedBox(height: 8),
            _buildTip('Use High Performance mode for smoother scrolling', isDarkMode),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTip(String text, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lightbulb_outline,
          size: 16,
          color: isDarkMode ? Colors.amber[300] : Colors.amber[700],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
