import 'package:flutter/material.dart';

/// CampusFind design system — Sunway University palette.
///
/// Colours are taken from the university's visual identity: the deep navy of
/// the crest and wordmark, the gold from the crest's sun motif, and the red
/// used on campus signage
///  and the Sunway logo.
///
/// Owned by Frontend Developer 1 (blueprint 5.5 `ThemeProvider`, "theme +
/// design system"). Every screen and shared widget reads colours, spacing
/// and component styles from here so the UI stays consistent (NFR11) and
/// Frontend Developer 2's screens inherit the same look for free.
class AppColors {
  AppColors._();

  /// Primary — Sunway navy. Buttons, links, active nav tab, focus.
  static const Color primary = Color(0xFF1B3A6B);
  static const Color primaryDark = Color(0xFF10254A);
  static const Color primaryLight = Color(0xFF3C63A0);

  /// Secondary accent — crest gold. Logo tile, promo banner, highlights.
  static const Color accent = Color(0xFFF2A900);
  static const Color accentSoft = Color(0xFFFDF1D4);
  static const Color accentText = Color(0xFF7A5300);

  /// Sunway red — campus signage. Used sparingly for alerts/urgent states.
  static const Color sunwayRed = Color(0xFFC8102E);

  /// Campus greens, used in the illustrated skyline.
  static const Color campusGreen = Color(0xFF3E8B4B);

  /// Lost / Found post-type badges.
  static const Color lostBg = Color(0xFFFBE3D5);
  static const Color lostFg = Color(0xFF9C3512);
  static const Color foundBg = Color(0xFFDCE6F5);
  static const Color foundFg = Color(0xFF1B3A6B);

  /// Neutral placeholder for missing images / skeletons.
  static const Color placeholder = Color(0xFFD8DDE5);
}

/// Shared spacing + radius scale. Screens use these instead of magic numbers.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const double cardRadius = 12;
  static const double controlRadius = 24;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      brightness: brightness,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: brightness == Brightness.light
          ? Colors.white
          : scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide: const BorderSide(color: AppColors.placeholder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide: const BorderSide(color: AppColors.placeholder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.light ? Colors.white : null,
        indicatorColor: AppColors.accentSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
