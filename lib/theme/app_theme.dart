import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Central theme definitions. Keeping both light and dark themes here (and
/// nowhere else) means visual polish work later only ever touches this
/// file plus the individual widgets, never screen logic.
///
/// This builds an explicit [ColorScheme] from [AppColors] rather than
/// [ColorScheme.fromSeed] — a seeded scheme derives every tone
/// algorithmically from one hue, which is what produces the generic
/// "Material blue app" look. This app has its own accent pair (cool/warm,
/// drawn from the sky language), so the scheme is assembled by hand.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _theme(AppColors.light, Brightness.light);
  static ThemeData dark() => _theme(AppColors.dark, Brightness.dark);

  static ThemeData _theme(ChromePalette palette, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accentCool,
      onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
      secondary: AppColors.accentWarm,
      onSecondary: Colors.black,
      error: AlertColors.severe,
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      surfaceContainerHighest: palette.surfaceVariant,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.divider,
      outlineVariant: palette.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      fontFamily: AppTypography.fontBody,
      visualDensity: VisualDensity.standard,
      textTheme: AppTypography.textTheme(palette),
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.navBackground,
        elevation: 0,
        height: 64,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: palette.navBackground,
        useIndicator: true,
      ),
      dividerTheme: DividerThemeData(color: palette.divider),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceVariant,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    );
  }
}
