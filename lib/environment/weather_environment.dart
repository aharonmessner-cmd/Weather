import 'package:flutter/material.dart';

import '../core/models/weather_condition.dart';
import '../core/utils/solar_position.dart';
import 'sky_palette.dart';
import 'sky_palette_resolver.dart';
import 'widgets/sky_background.dart';

/// "You're looking through a window at the current sky." This is that
/// window: a reusable environment that paints a continuously-computed sky
/// behind [child] and makes the resolved [SkyPalette] available to it via
/// [WeatherEnvironment.paletteOf].
///
/// Deliberately takes raw inputs (condition, time, location) rather than a
/// pre-resolved palette, so callers never hand-pick colors — the sky is
/// always derived, never art-directed per screen.
///
/// [heroContentBrightness] on the resolved palette is intentionally
/// **not** the same thing as the app's [ThemeMode]. A sky rendered here at
/// 10 PM is dark regardless of whether the app is in light or dark mode;
/// [Theme.of(context).brightness] only nudges saturation within the
/// palette family the actual sun position already chose. See
/// `sky_palette_resolver.dart`.
///
/// Sunrise/sunset aren't separate inputs here: continuous solar elevation
/// (derived from [latitude]/[longitude]/[now]) already supersedes them for
/// rendering. Consumers that need an actual sunrise/sunset moment (e.g. a
/// sunrise-arc metric card) compute it separately via
/// `core/utils/sun_times.dart`.
class WeatherEnvironment extends StatelessWidget {
  const WeatherEnvironment({
    super.key,
    required this.condition,
    required this.now,
    required this.latitude,
    required this.longitude,
    required this.child,
    this.temperatureFahrenheit,
  });

  final WeatherCondition condition;
  final DateTime now;
  final double latitude;
  final double longitude;
  final Widget child;

  /// Not yet used by the resolver — reserved for future heat-haze/cold-tint
  /// effects (Stage 7) so this constructor doesn't need a breaking change
  /// to add them later.
  final double? temperatureFahrenheit;

  @override
  Widget build(BuildContext context) {
    final uiBrightness = Theme.of(context).brightness;
    final position = computeSolarPosition(
      latitude: latitude,
      longitude: longitude,
      utcTime: now.toUtc(),
    );
    final palette = resolveSkyPalette(position: position, condition: condition, uiBrightness: uiBrightness);

    return _SkyPaletteScope(
      palette: palette,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SkyBackground(palette: palette),
          child,
        ],
      ),
    );
  }

  /// Reads the nearest ancestor [WeatherEnvironment]'s resolved palette —
  /// used by hero/content widgets that need to adapt their contrast to
  /// the sky they're sitting on (see `GlassStyle.onSky`).
  static SkyPalette paletteOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SkyPaletteScope>();
    assert(scope != null, 'WeatherEnvironment.paletteOf() called with no WeatherEnvironment ancestor.');
    return scope!.palette;
  }
}

class _SkyPaletteScope extends InheritedWidget {
  const _SkyPaletteScope({required this.palette, required super.child});

  final SkyPalette palette;

  @override
  bool updateShouldNotify(_SkyPaletteScope oldWidget) => true;
}
