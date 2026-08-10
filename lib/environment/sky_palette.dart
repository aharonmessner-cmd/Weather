import 'package:flutter/material.dart';

/// Which particle shape [precipitationIntensity] should render as. Kept as
/// a small enum rather than a continuous field deliberately: unlike every
/// other field on [SkyPalette], "is this rain or snow" has no meaningful
/// continuous interpolation between its states — it comes straight from
/// the categorical [WeatherCondition] the resolver was given, same as
/// [SkyPalette.isSunVisible].
enum SkyPrecipitationKind { none, rain, snow }

/// A fully-resolved, continuous description of what the sky should look
/// like right now. Every field here is either a color or a 0–1 scalar —
/// there is deliberately no enum/bucket in this class, so nothing that
/// consumes it can render a hard cut between two adjacent moments.
///
/// Produced by [resolveSkyPalette] in `sky_palette_resolver.dart`, and
/// consumed by the widgets in `widgets/`.
@immutable
class SkyPalette {
  const SkyPalette({
    required this.topColor,
    required this.bottomColor,
    required this.midColor,
    this.midColorStop = 0.62,
    required this.starOpacity,
    required this.cloudOpacity,
    required this.cloudCoverageFraction,
    required this.horizonGlowColor,
    required this.horizonGlowIntensity,
    required this.sunMoonVisibility,
    required this.isSunVisible,
    required this.sunMoonElevationFraction,
    required this.sunMoonAzimuthDegrees,
    required this.precipitationIntensity,
    this.precipitationKind = SkyPrecipitationKind.none,
    required this.stormFlicker,
    required this.heroContentBrightness,
  });

  /// Vertical gradient endpoints (top of the sky, bottom near the
  /// horizon). Two stops, blended continuously as the sun moves — a warm
  /// horizon moment is expressed via [horizonGlowColor]/[horizonGlowIntensity]
  /// layered near the bottom, not a third gradient stop, so cloudy skies
  /// can dampen the glow without needing a whole separate gradient.
  final Color topColor;
  final Color bottomColor;

  /// A third gradient stop between [topColor] and [bottomColor], at
  /// [midColorStop]. Always present, but computed so that outside the
  /// sunrise/sunset elevation window it equals the straight interpolation
  /// [topColor]/[bottomColor] would already produce there — i.e. it's a
  /// visual no-op at midday/midnight, and only reads as a distinct warm
  /// band low in the sky during dawn/dusk, fading in and out continuously
  /// with elevation like everything else here.
  final Color midColor;
  final double midColorStop;

  /// 0 (invisible) – 1 (fully visible). Naturally near 0 in daylight and
  /// near 1 deep in a clear night; also reduced by cloud cover.
  final double starOpacity;

  /// 0–1 overall opacity of the cloud layer widget.
  final double cloudOpacity;

  /// 0–1 how much of the sky's width clouds should occupy — drives count
  /// and spread in `sky_clouds.dart`, independent of [cloudOpacity].
  final double cloudCoverageFraction;

  /// The warm (or, for storms, cool-dark) glow color layered near the
  /// bottom of the sky.
  final Color horizonGlowColor;

  /// 0–1 strength of that glow — naturally peaks near sunrise/sunset and
  /// fades toward both midday and deep night.
  final double horizonGlowIntensity;

  /// 0–1 how visible the sun/moon glyph should be (attenuated by cloud
  /// cover and fog-like conditions).
  final double sunMoonVisibility;

  /// Whether the glyph to show is the sun (true) or the moon (false).
  final bool isSunVisible;

  /// 0 (horizon) – 1 (top of the sky) vertical placement for the sun/moon
  /// glyph, derived from continuous solar elevation.
  final double sunMoonElevationFraction;

  /// Horizontal placement in degrees (0–360, matching solar azimuth) for
  /// the sun/moon glyph.
  final double sunMoonAzimuthDegrees;

  /// 0–1 suggested strength of the (currently subtle) precipitation
  /// overlay.
  final double precipitationIntensity;

  /// Which particle shape the precipitation overlay should draw — see
  /// [SkyPrecipitationKind]. `none` when [precipitationIntensity] is 0.
  final SkyPrecipitationKind precipitationKind;

  /// Whether this palette permits an occasional lightning flicker
  /// (thunderstorm conditions only).
  final bool stormFlicker;

  /// Whether content sitting on top of this sky should use light-on-dark
  /// or dark-on-light styling. Derived from the sky's own resolved
  /// luminance — see `GlassStyle.onSky` for how this is consumed. This is
  /// independent of the app's `ThemeMode`.
  final Brightness heroContentBrightness;
}
