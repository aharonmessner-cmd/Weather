import 'package:flutter/material.dart';

/// Chrome colors for one [Brightness]: everything that is NOT the sky —
/// the bottom nav/rail, the Locations/Alerts/Settings screens, dialogs,
/// form fields. The Weather tab's hero content instead reads its contrast
/// from `SkyPalette.heroContentBrightness` (see `lib/environment/`), since
/// that has to respond to the actual sky, not to this app-wide setting.
class ChromePalette {
  const ChromePalette({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.navBackground,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;
  final Color navBackground;
}

/// App-wide color tokens. Deliberately not a single `ColorScheme.fromSeed`
/// — this app has its own identity (a cool/warm accent pair drawn from the
/// sky language) rather than a generic Material seed color.
class AppColors {
  const AppColors._();

  static const light = ChromePalette(
    background: Color(0xFFF3F5FB),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE7EBF5),
    textPrimary: Color(0xFF11131F),
    textSecondary: Color(0x9E11131F),
    textTertiary: Color(0x6611131F),
    divider: Color(0x1611131F),
    navBackground: Color(0xE6FFFFFF),
  );

  static const dark = ChromePalette(
    background: Color(0xFF0A0D1F),
    surface: Color(0xFF141830),
    surfaceVariant: Color(0xFF1D2240),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    textTertiary: Color(0x61FFFFFF),
    divider: Color(0x1FFFFFFF),
    navBackground: Color(0xCC0A0D1F),
  );

  /// Cool accent — precipitation, wind, visibility. Consistent across both
  /// chrome brightnesses so it reads as this app's identity, not a
  /// theme-dependent color.
  static const accentCool = Color(0xFF54C7EA);
  static const accentCoolDeep = Color(0xFF2FA0C9);

  /// Warm accent — sun, sunrise, precipitation-adjacent warnings.
  static const accentWarm = Color(0xFFFFC94A);
  static const accentWarmDeep = Color(0xFFFF9B3D);
}

/// Severity accent colors for weather alerts. Kept separate from
/// [AppColors] since alert severity is an NWS domain concept
/// (`Extreme`/`Severe`/`Moderate`/`Minor`), not a UI role, and needs to
/// read clearly against both glass-on-sky and flat chrome surfaces.
class AlertColors {
  const AlertColors._();

  static const extreme = Color(0xFFE0483F);
  static const severe = Color(0xFFF2793A);
  static const moderate = Color(0xFFF0B429);
  static const minor = Color(0xFF54A6F0);
  static const unknown = Color(0xFF8E93A8);
}
