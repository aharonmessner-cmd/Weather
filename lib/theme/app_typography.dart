import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's two-family type scale: **Outfit** for display/numeric content
/// (headings, temperatures, big numbers) and **Inter** for body text and
/// labels. Both are bundled as local assets (see `assets/fonts/`) — no
/// runtime font fetching, so typography is identical online or offline.
///
/// The temperature hero does not use this scale — it's stylized enough
/// (extreme vertical stretch) to warrant its own dedicated styles, defined
/// alongside the widget that uses them in
/// `features/weather/presentation/widgets/temperature_hero.dart`.
class AppTypography {
  const AppTypography._();

  static const fontDisplay = 'Outfit';
  static const fontBody = 'Inter';

  static TextTheme textTheme(ChromePalette palette) {
    final base = TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 57,
        fontWeight: FontWeight.w200,
        letterSpacing: -1.5,
        color: palette.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: palette.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: palette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontBody,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: palette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontBody,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: palette.textSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: fontBody,
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: palette.textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: fontBody,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      labelSmall: TextStyle(
        fontFamily: fontBody,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: palette.textTertiary,
      ),
    );
    return base;
  }
}
