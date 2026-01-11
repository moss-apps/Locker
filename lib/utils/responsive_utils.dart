import 'package:flutter/material.dart';

/// Material Design responsive breakpoints
/// Based on https://m3.material.io/foundations/layout/applying-layout/window-size-classes
class ScreenBreakpoints {
  ScreenBreakpoints._();

  /// Compact: phones in portrait (< 600dp)
  static const double compact = 600;

  /// Medium: small tablets, foldables (600-840dp)
  static const double medium = 840;

  /// Expanded: tablets, desktop (> 840dp)
  static const double expanded = 1200;
}

/// Device type based on screen width
enum DeviceType { compact, medium, expanded }

/// Responsive utilities for adaptive layouts
class ResponsiveUtils {
  ResponsiveUtils._();

  /// Get the device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < ScreenBreakpoints.compact) {
      return DeviceType.compact;
    } else if (width < ScreenBreakpoints.medium) {
      return DeviceType.medium;
    } else {
      return DeviceType.expanded;
    }
  }

  /// Check if device is compact (phone)
  static bool isCompact(BuildContext context) =>
      getDeviceType(context) == DeviceType.compact;

  /// Check if device is medium (small tablet)
  static bool isMedium(BuildContext context) =>
      getDeviceType(context) == DeviceType.medium;

  /// Check if device is expanded (tablet/desktop)
  static bool isExpanded(BuildContext context) =>
      getDeviceType(context) == DeviceType.expanded;

  /// Get responsive grid column count
  ///
  /// Returns [compact] columns for phones, [medium] for tablets,
  /// [expanded] for large screens.
  static int getGridColumnCount(
    BuildContext context, {
    int compact = 3,
    int medium = 4,
    int expanded = 6,
  }) {
    switch (getDeviceType(context)) {
      case DeviceType.compact:
        return compact;
      case DeviceType.medium:
        return medium;
      case DeviceType.expanded:
        return expanded;
    }
  }

  /// Get responsive grid column count based on available width (LayoutBuilder)
  ///
  /// Use this inside a LayoutBuilder for more accurate sizing based on
  /// the parent widget's constraints rather than screen size.
  static int getGridColumnCountFromWidth(
    double width, {
    int compact = 3,
    int medium = 4,
    int expanded = 6,
  }) {
    if (width < ScreenBreakpoints.compact) {
      return compact;
    } else if (width < ScreenBreakpoints.medium) {
      return medium;
    } else {
      return expanded;
    }
  }

  /// Get adaptive spacing based on screen size
  static double getSpacing(
    BuildContext context, {
    double compact = 8,
    double medium = 12,
    double expanded = 16,
  }) {
    switch (getDeviceType(context)) {
      case DeviceType.compact:
        return compact;
      case DeviceType.medium:
        return medium;
      case DeviceType.expanded:
        return expanded;
    }
  }

  /// Get adaptive padding based on screen size
  static EdgeInsets getPadding(
    BuildContext context, {
    EdgeInsets compact = const EdgeInsets.all(8),
    EdgeInsets medium = const EdgeInsets.all(12),
    EdgeInsets expanded = const EdgeInsets.all(16),
  }) {
    switch (getDeviceType(context)) {
      case DeviceType.compact:
        return compact;
      case DeviceType.medium:
        return medium;
      case DeviceType.expanded:
        return expanded;
    }
  }

  /// Get screen width percentage
  static double widthPercent(BuildContext context, double percent) {
    return MediaQuery.sizeOf(context).width * (percent / 100);
  }

  /// Get screen height percentage
  static double heightPercent(BuildContext context, double percent) {
    return MediaQuery.sizeOf(context).height * (percent / 100);
  }
}

/// A widget that builds different layouts based on screen size
///
/// Provides a simplified interface over LayoutBuilder with pre-calculated
/// responsive values.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  /// Builder function that receives context and responsive values
  final Widget Function(
    BuildContext context,
    DeviceType deviceType,
    BoxConstraints constraints,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveUtils.getDeviceType(context);
        return builder(context, deviceType, constraints);
      },
    );
  }
}

/// A responsive grid delegate that automatically adjusts column count
class ResponsiveGridDelegate extends SliverGridDelegateWithFixedCrossAxisCount {
  ResponsiveGridDelegate({
    required int crossAxisCount,
    double mainAxisSpacing = 4,
    double crossAxisSpacing = 4,
    double childAspectRatio = 1,
  }) : super(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        );

  /// Create a responsive grid delegate based on context
  factory ResponsiveGridDelegate.responsive(
    BuildContext context, {
    int compact = 3,
    int medium = 4,
    int expanded = 6,
    double mainAxisSpacing = 4,
    double crossAxisSpacing = 4,
    double childAspectRatio = 1,
  }) {
    return ResponsiveGridDelegate(
      crossAxisCount: ResponsiveUtils.getGridColumnCount(
        context,
        compact: compact,
        medium: medium,
        expanded: expanded,
      ),
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
    );
  }
}
