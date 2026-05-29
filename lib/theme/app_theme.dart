import 'package:flutter/material.dart';

// Universal Theme Constants
class AppTheme {
  // Colors
  static const Color seedColor = Colors.blue;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;

  // Layout
  static const double borderRadius = 20;
  static const double padding = 16;
  static const double spacing = 12;

  // Music Player Specific
  static const double musicPlayerRadius = 28;
}

ThemeData buildTheme(Brightness brightness, Color seedColor) {
  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: seedColor, 
  );

  return baseTheme.copyWith(
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
