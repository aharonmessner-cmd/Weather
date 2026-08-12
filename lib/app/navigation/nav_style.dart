import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_platform.dart';

/// The platform-specific "recipe" for the custom navigation surfaces
/// (bottom bar and side rail) — how much blur, how opaque, whether it
/// floats above the content with a margin or sits flush against the
/// screen edge, and what shadow gives it depth. Colors themselves still
/// come from [ChromePalette] (the same tokens every other surface in the
/// app uses), so a platform only changes the *treatment*, never invents a
/// new color language.
///
/// Deliberately three distinct idioms per the platform-aware navigation
/// requirement: iOS gets a restrained Liquid-Glass-style floating
/// treatment, Android its own translucent-but-edge-attached idiom (never
/// the iOS recipe verbatim), and web/desktop a flatter, closer-to-static
/// surface with no blur, since there's no single native OS nav chrome to
/// draw from there.
class NavPlatformStyle {
  const NavPlatformStyle({
    required this.blurSigma,
    required this.fill,
    required this.border,
    required this.borderWidth,
    required this.floating,
    required this.shadow,
  });

  final double blurSigma;
  final Color fill;
  final Color border;
  final double borderWidth;

  /// iOS: a pill-like bar inset from the screen edges with margin on all
  /// sides. Android/web: attached flush to the edge it sits on (bottom
  /// for the nav bar, side for the rail), like the native chrome each
  /// platform actually uses.
  final bool floating;

  final List<BoxShadow> shadow;

  static NavPlatformStyle of(AppPlatform platform, ChromePalette palette, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (platform) {
      case AppPlatform.ios:
        return NavPlatformStyle(
          blurSigma: 30,
          fill: palette.navBackground.withValues(alpha: dark ? 0.5 : 0.6),
          border: Colors.white.withValues(alpha: dark ? 0.16 : 0.55),
          borderWidth: 1,
          floating: true,
          shadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.35 : 0.15),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        );
      case AppPlatform.android:
        return NavPlatformStyle(
          blurSigma: 16,
          fill: palette.navBackground,
          border: palette.divider,
          borderWidth: 1,
          floating: false,
          shadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.3 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        );
      case AppPlatform.webOrDesktop:
        return NavPlatformStyle(
          blurSigma: 0,
          fill: palette.navBackground,
          border: palette.divider,
          borderWidth: 1,
          floating: false,
          shadow: const [],
        );
    }
  }
}
