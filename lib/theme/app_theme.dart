import 'package:flutter/material.dart';

/// Central theme definitions. Keeping both light and dark themes here (and
/// nowhere else) means visual polish work later only ever touches this
/// file plus the individual widgets, never screen logic.
class AppTheme {
  const AppTheme._();

  static const _seedColor = Color(0xFF3D7BFF);

  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor, brightness: brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      visualDensity: VisualDensity.standard,
      textTheme: _textTheme(colorScheme),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        height: 64,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        useIndicator: true,
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    const base = Typography.blackMountainView;
    return base.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ).copyWith(
      displayLarge: const TextStyle(fontSize: 96, fontWeight: FontWeight.w200, letterSpacing: -2),
      headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.5),
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    );
  }
}

/// Severity-driven accent colors for weather alerts, kept separate from the
/// main [ColorScheme] since alert severity is a domain concept (NWS's
/// `Extreme`/`Severe`/`Moderate`/`Minor`) rather than a UI role.
class AlertColors {
  const AlertColors._();

  static const extreme = Color(0xFFB3261E);
  static const severe = Color(0xFFE4572E);
  static const moderate = Color(0xFFE8A400);
  static const minor = Color(0xFF3D7BFF);
  static const unknown = Color(0xFF6B7280);
}
