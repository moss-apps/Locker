import 'package:flutter/material.dart';

/// Accent color option for app theming
class AccentColorOption {
  final String id;
  final String name;
  final Color lightColor;
  final Color darkColor;
  final Color lightColorVariant;
  final Color darkColorVariant;

  const AccentColorOption({
    required this.id,
    required this.name,
    required this.lightColor,
    required this.darkColor,
    required this.lightColorVariant,
    required this.darkColorVariant,
  });

  /// Get the appropriate color based on brightness
  Color getColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkColor : lightColor;
  }

  /// Get the appropriate variant color based on brightness
  Color getVariantColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkColorVariant : lightColorVariant;
  }
}

/// Predefined accent color options
class AccentColors {
  AccentColors._();

  static const AccentColorOption blue = AccentColorOption(
    id: 'blue',
    name: 'Ocean Blue',
    lightColor: Color(0xFF1976D2),
    darkColor: Color(0xFF5C9CE6),
    lightColorVariant: Color(0xFF42A5F5),
    darkColorVariant: Color(0xFF7AB3F0),
  );

  static const AccentColorOption purple = AccentColorOption(
    id: 'purple',
    name: 'Royal Purple',
    lightColor: Color(0xFF7B1FA2),
    darkColor: Color(0xFFAB47BC),
    lightColorVariant: Color(0xFF9C27B0),
    darkColorVariant: Color(0xFFBA68C8),
  );

  static const AccentColorOption teal = AccentColorOption(
    id: 'teal',
    name: 'Emerald Teal',
    lightColor: Color(0xFF00796B),
    darkColor: Color(0xFF26A69A),
    lightColorVariant: Color(0xFF009688),
    darkColorVariant: Color(0xFF4DB6AC),
  );

  static const AccentColorOption green = AccentColorOption(
    id: 'green',
    name: 'Forest Green',
    lightColor: Color(0xFF388E3C),
    darkColor: Color(0xFF66BB6A),
    lightColorVariant: Color(0xFF4CAF50),
    darkColorVariant: Color(0xFF81C784),
  );

  static const AccentColorOption orange = AccentColorOption(
    id: 'orange',
    name: 'Sunset Orange',
    lightColor: Color(0xFFE64A19),
    darkColor: Color(0xFFFF7043),
    lightColorVariant: Color(0xFFFF5722),
    darkColorVariant: Color(0xFFFF8A65),
  );

  static const AccentColorOption pink = AccentColorOption(
    id: 'pink',
    name: 'Rose Pink',
    lightColor: Color(0xFFC2185B),
    darkColor: Color(0xFFEC407A),
    lightColorVariant: Color(0xFFE91E63),
    darkColorVariant: Color(0xFFF06292),
  );

  static const AccentColorOption red = AccentColorOption(
    id: 'red',
    name: 'Ruby Red',
    lightColor: Color(0xFFD32F2F),
    darkColor: Color(0xFFEF5350),
    lightColorVariant: Color(0xFFF44336),
    darkColorVariant: Color(0xFFE57373),
  );

  static const AccentColorOption indigo = AccentColorOption(
    id: 'indigo',
    name: 'Deep Indigo',
    lightColor: Color(0xFF303F9F),
    darkColor: Color(0xFF5C6BC0),
    lightColorVariant: Color(0xFF3F51B5),
    darkColorVariant: Color(0xFF7986CB),
  );

  static const AccentColorOption cyan = AccentColorOption(
    id: 'cyan',
    name: 'Sky Cyan',
    lightColor: Color(0xFF0097A7),
    darkColor: Color(0xFF26C6DA),
    lightColorVariant: Color(0xFF00BCD4),
    darkColorVariant: Color(0xFF4DD0E1),
  );

  static const AccentColorOption amber = AccentColorOption(
    id: 'amber',
    name: 'Golden Amber',
    lightColor: Color(0xFFF57C00),
    darkColor: Color(0xFFFFB74D),
    lightColorVariant: Color(0xFFFF9800),
    darkColorVariant: Color(0xFFFFCC80),
  );

  static const AccentColorOption gunmetal = AccentColorOption(
    id: 'gunmetal',
    name: 'Gunmetal Gray',
    lightColor: Color(0xFF353E43),
    darkColor: Color(0xFF353E43),
    lightColorVariant: Color(0xFF4A565C),
    darkColorVariant: Color(0xFF4A565C),
  );

  /// List of all available accent colors
  static const List<AccentColorOption> all = [
    blue,
    purple,
    teal,
    green,
    orange,
    pink,
    red,
    indigo,
    cyan,
    amber,
    gunmetal,
  ];

  /// Get accent color by ID
  static AccentColorOption? getById(String id) {
    try {
      return all.firstWhere((color) => color.id == id);
    } catch (e) {
      return null;
    }
  }
}
