import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/frame_rate_optimizer.dart';

/// Performance overlay widget for debugging and monitoring
/// Shows FPS, jank percentage, and other metrics
class PerformanceOverlayWidget extends StatefulWidget {
  final Widget child;
  final bool showOverlay;
  
  const PerformanceOverlayWidget({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<PerformanceOverlayWidget> createState() => _PerformanceOverlayWidgetState();
}

class _PerformanceOverlayWidgetState extends State<PerformanceOverlayWidget> {
  Timer? _updateTimer;
  PerformanceMetrics? _metrics;
  final FrameRateOptimizer _optimizer = FrameRateOptimizer();
  
  @override
  void initState() {
    super.initState();
    if (widget.showOverlay) {
      _startUpdating();
    }
  }
  
  @override
  void didUpdateWidget(PerformanceOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showOverlay != oldWidget.showOverlay) {
      if (widget.showOverlay) {
        _startUpdating();
      } else {
        _stopUpdating();
      }
    }
  }
  
  void _startUpdating() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _metrics = _optimizer.getMetrics();
        });
      }
    });
  }
  
  void _stopUpdating() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }
  
  @override
  void dispose() {
    _stopUpdating();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay && _metrics != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: _buildOverlay(),
          ),
      ],
    );
  }
  
  Widget _buildOverlay() {
    final metrics = _metrics!;
    final isGood = _optimizer.isPerformanceGood;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMetricRow(
            'FPS',
            metrics.averageFps.toStringAsFixed(1),
            isGood ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 4),
          _buildMetricRow(
            'Jank',
            '${metrics.jankPercentage.toStringAsFixed(1)}%',
            metrics.jankPercentage < 5 ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 4),
          _buildMetricRow(
            'Dropped',
            '${metrics.droppedFrames}',
            metrics.droppedFrames < 10 ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
