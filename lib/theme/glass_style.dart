import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A single glass-card recipe: fill, blur, border, radius.
///
/// Deliberately modest fill opacity and moderate blur — per the design
/// direction, cards are meant to stay subordinate to the sky behind them.
/// A card should read as "a pane of glass in front of the sky," not as an
/// opaque tile that happens to sit on a gradient. If a future change makes
/// a card look like a normal solid Material card, the fill opacity here is
/// almost certainly too high.
class GlassStyle {
  const GlassStyle({
    required this.fill,
    required this.blurSigma,
    required this.border,
    required this.borderWidth,
    required this.radius,
  });

  final Color fill;
  final double blurSigma;
  final Color border;
  final double borderWidth;
  final double radius;

  static const double radiusDefault = 22;
  static const double radiusSmall = 14;

  /// Cards sitting directly on [WeatherEnvironment] in dark chrome — real
  /// backdrop blur, low fill opacity so the sky reads through clearly.
  static const onSkyDark = GlassStyle(
    fill: Color(0x17FFFFFF),
    blurSigma: 24,
    border: Color(0x24FFFFFF),
    borderWidth: 1,
    radius: radiusDefault,
  );

  /// Cards sitting directly on [WeatherEnvironment] in light chrome. A
  /// daytime sky is already bright, so this needs a bit more fill to keep
  /// text legible — still translucent, not solid.
  static const onSkyLight = GlassStyle(
    fill: Color(0x59FFFFFF),
    blurSigma: 20,
    border: Color(0x40FFFFFF),
    borderWidth: 1,
    radius: radiusDefault,
  );

  /// Picks the on-sky variant for the given content brightness. Follows
  /// the same convention as [ThemeData.brightness]: `Brightness.dark`
  /// means "this is a dark backdrop, so content should be light" — i.e. a
  /// night sky, which pairs with [onSkyDark]'s white-on-translucent-dark
  /// treatment. `Brightness.light` means a bright backdrop (a daytime
  /// sky), pairing with [onSkyLight]'s more-opaque white card.
  ///
  /// This is keyed on the *sky's* resolved content brightness
  /// (`SkyPalette.heroContentBrightness`), not the app's `ThemeMode` — see
  /// the module doc in `lib/environment/`.
  static GlassStyle onSky(Brightness skyContentBrightness) =>
      skyContentBrightness == Brightness.dark ? onSkyDark : onSkyLight;

  /// For screens with no dynamic sky behind them (Locations, Alerts,
  /// Settings) — there's nothing to blur, so this is just a flat surface
  /// with a hairline border, keyed on the app's normal chrome palette.
  static GlassStyle chrome(ChromePalette palette) => GlassStyle(
        fill: palette.surface,
        blurSigma: 0,
        border: palette.divider,
        borderWidth: 1,
        radius: radiusDefault,
      );
}
