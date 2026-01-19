// lib/core/dev_tools/dev_tools_theme.dart

import 'package:flutter/material.dart';

/// Theme configuration for Dev Tools
/// Allows customization of colors to match your app's branding
class DevToolsTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color successColor;
  final Color warningColor;
  final Color errorColor;
  final Color backgroundColor;
  final Color textColor;
  final Color cardColor;

  const DevToolsTheme({
    this.primaryColor = const Color(0xFF6200EE),
    this.secondaryColor = const Color(0xFF03DAC6),
    this.successColor = const Color(0xFF4CAF50),
    this.warningColor = const Color(0xFFFF9800),
    this.errorColor = const Color(0xFFF44336),
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF212121),
    this.cardColor = Colors.white,
  });

  /// Create a theme from your app's primary color
  factory DevToolsTheme.fromAppColor(Color appPrimaryColor) {
    return DevToolsTheme(
      primaryColor: appPrimaryColor,
      secondaryColor: _generateSecondaryColor(appPrimaryColor),
    );
  }

  /// Material Design Blue theme (default)
  factory DevToolsTheme.material() {
    return const DevToolsTheme(
      primaryColor: Color(0xFF2196F3),
      secondaryColor: Color(0xFF03DAC6),
    );
  }

  /// Dark theme
  factory DevToolsTheme.dark() {
    return const DevToolsTheme(
      primaryColor: Color(0xFFBB86FC),
      secondaryColor: Color(0xFF03DAC6),
      backgroundColor: Color(0xFF121212),
      textColor: Colors.white,
      cardColor: Color(0xFF1E1E1E),
    );
  }

  /// Green theme
  factory DevToolsTheme.green() {
    return const DevToolsTheme(
      primaryColor: Color(0xFF4CAF50),
      secondaryColor: Color(0xFF8BC34A),
    );
  }

  /// Orange theme
  factory DevToolsTheme.orange() {
    return const DevToolsTheme(
      primaryColor: Color(0xFFFF9800),
      secondaryColor: Color(0xFFFFB74D),
    );
  }

  /// Purple theme
  factory DevToolsTheme.purple() {
    return const DevToolsTheme(
      primaryColor: Color(0xFF9C27B0),
      secondaryColor: Color(0xFFBA68C8),
    );
  }

  /// Red theme
  factory DevToolsTheme.red() {
    return const DevToolsTheme(
      primaryColor: Color(0xFFF44336),
      secondaryColor: Color(0xFFE57373),
    );
  }

  /// Teal theme
  factory DevToolsTheme.teal() {
    return const DevToolsTheme(
      primaryColor: Color(0xFF009688),
      secondaryColor: Color(0xFF4DB6AC),
    );
  }

  static Color _generateSecondaryColor(Color primary) {
    final hslColor = HSLColor.fromColor(primary);
    return hslColor
        .withLightness((hslColor.lightness + 0.2).clamp(0.0, 1.0))
        .toColor();
  }

  DevToolsTheme copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? successColor,
    Color? warningColor,
    Color? errorColor,
    Color? backgroundColor,
    Color? textColor,
    Color? cardColor,
  }) {
    return DevToolsTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      errorColor: errorColor ?? this.errorColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      cardColor: cardColor ?? this.cardColor,
    );
  }
}
