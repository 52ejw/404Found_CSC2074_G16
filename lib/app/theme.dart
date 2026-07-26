import 'package:flutter/material.dart';

/// Placeholder theme so the app has consistent Material 3 styling before
/// Frontend Developer 1 builds out the real design system (blueprint 5.5
/// `ThemeProvider`, "theme + design system" under Frontend 1's absorbed
/// arch work).
class AppTheme {
  AppTheme._();

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
  );
}
