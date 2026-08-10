import 'package:flutter/material.dart';

import '../core/models/weather_condition.dart';
import '../core/utils/solar_position.dart';
import 'sky_palette.dart';

/// One reference point on the continuous elevation curve the sky is
/// interpolated along. Not exported — an implementation detail of
/// [resolveSkyPalette]. Add more anchors here for richer transitions;
/// nothing downstream needs to change since consumers only ever see the
/// already-interpolated [SkyPalette].
class _SkyAnchor {
  const _SkyAnchor({
    required this.elevation,
    required this.topColor,
    required this.bottomColor,
    required this.starOpacity,
    required this.horizonGlowIntensity,
    required this.horizonGlowColor,
  });

  final double elevation;
  final Color topColor;
  final Color bottomColor;
  final double starOpacity;
  final double horizonGlowIntensity;
  final Color horizonGlowColor;
}

/// Anchors ordered by elevation, deep night to high sun. [resolveSkyPalette]
/// finds the two bracketing this moment's actual elevation and blends
/// between them — every value in between is a smooth interpolation, never
/// a jump cut. Denser near the horizon (-8 to +6), where real skies change
/// fastest; sparser above +20, where they barely change at all between
/// mid-morning and mid-afternoon.
const _dawnDuskGlow = Color(0xFFFF9D6C);
const _goldenGlow = Color(0xFFFFC98A);

final List<_SkyAnchor> _anchors = [
  const _SkyAnchor(
    elevation: -90,
    topColor: Color(0xFF05070F),
    bottomColor: Color(0xFF0A1024),
    starOpacity: 1.0,
    horizonGlowIntensity: 0,
    horizonGlowColor: _dawnDuskGlow,
  ),
  const _SkyAnchor(
    elevation: -18,
    topColor: Color(0xFF070B1D),
    bottomColor: Color(0xFF141B3A),
    starOpacity: 0.9,
    // A faint hint of glow this far out, rather than a flat zero, so the
    // approach to dawn (or the fade after dusk) starts gently instead of
    // the glow feeling like it switches on only once it crosses -8°.
    horizonGlowIntensity: 0.03,
    horizonGlowColor: _dawnDuskGlow,
  ),
  const _SkyAnchor(
    elevation: -8,
    topColor: Color(0xFF0B1330),
    bottomColor: Color(0xFF24305C),
    starOpacity: 0.5,
    horizonGlowIntensity: 0.15,
    horizonGlowColor: _dawnDuskGlow,
  ),
  const _SkyAnchor(
    elevation: -3,
    topColor: Color(0xFF14205A),
    bottomColor: Color(0xFF4A3A72),
    starOpacity: 0.15,
    horizonGlowIntensity: 0.55,
    horizonGlowColor: _dawnDuskGlow,
  ),
  const _SkyAnchor(
    elevation: 0,
    topColor: Color(0xFF2A4A8C),
    bottomColor: Color(0xFFFF9D6C),
    starOpacity: 0.02,
    horizonGlowIntensity: 1.0,
    horizonGlowColor: _dawnDuskGlow,
  ),
  const _SkyAnchor(
    elevation: 6,
    topColor: Color(0xFF3E7BC4),
    bottomColor: Color(0xFFFFC98A),
    starOpacity: 0,
    horizonGlowIntensity: 0.6,
    horizonGlowColor: _goldenGlow,
  ),
  const _SkyAnchor(
    elevation: 20,
    topColor: Color(0xFF4F9BE0),
    bottomColor: Color(0xFFBFE0F5),
    starOpacity: 0,
    horizonGlowIntensity: 0.18,
    horizonGlowColor: _goldenGlow,
  ),
  // Softens the 20°->60° stretch into two smaller steps rather than one
  // longer linear one, for a gentler taper as the glow finishes fading.
  const _SkyAnchor(
    elevation: 35,
    topColor: Color(0xFF479AE2),
    bottomColor: Color(0xFFC7E5F9),
    starOpacity: 0,
    horizonGlowIntensity: 0.06,
    horizonGlowColor: _goldenGlow,
  ),
  const _SkyAnchor(
    elevation: 60,
    topColor: Color(0xFF3E8FDE),
    bottomColor: Color(0xFFCFEAFB),
    starOpacity: 0,
    horizonGlowIntensity: 0,
    horizonGlowColor: _goldenGlow,
  ),
];

/// How a [WeatherCondition] modifies the elevation-driven base sky:
/// how much cloud to show, how much it should flatten/desaturate the
/// gradient and dim the glow, and whether precipitation/storm effects
/// apply. A simple, deliberately extensible mapping — refining any one
/// condition's numbers later never touches the resolver's interpolation
/// logic.
class _ConditionEffects {
  const _ConditionEffects({
    this.cloudCoverage = 0,
    this.precipitationIntensity = 0,
    this.precipitationKind = SkyPrecipitationKind.none,
    this.stormFlicker = false,
    this.overcastFlattening = 0,
  });

  final double cloudCoverage;
  final double precipitationIntensity;
  final SkyPrecipitationKind precipitationKind;
  final bool stormFlicker;

  /// 0–1: how much this condition should mute the gradient/glow toward a
  /// flat overcast gray, on top of the cloud layer itself.
  final double overcastFlattening;
}

_ConditionEffects _effectsFor(WeatherCondition condition) {
  switch (condition) {
    case WeatherCondition.clearSky:
      return const _ConditionEffects(cloudCoverage: 0);
    case WeatherCondition.mostlyClear:
      return const _ConditionEffects(cloudCoverage: 0.15);
    case WeatherCondition.partlyCloudy:
      return const _ConditionEffects(cloudCoverage: 0.4);
    case WeatherCondition.mostlyCloudy:
      return const _ConditionEffects(cloudCoverage: 0.7, overcastFlattening: 0.2);
    case WeatherCondition.overcast:
      return const _ConditionEffects(cloudCoverage: 0.9, overcastFlattening: 0.45);
    case WeatherCondition.fog:
    case WeatherCondition.hazy:
    case WeatherCondition.smoke:
    case WeatherCondition.dust:
      return const _ConditionEffects(cloudCoverage: 0.55, overcastFlattening: 0.5);
    case WeatherCondition.drizzle:
      return const _ConditionEffects(
        cloudCoverage: 0.75,
        precipitationIntensity: 0.25,
        precipitationKind: SkyPrecipitationKind.rain,
        overcastFlattening: 0.3,
      );
    case WeatherCondition.rain:
    case WeatherCondition.rainShowers:
      return const _ConditionEffects(
        cloudCoverage: 0.85,
        precipitationIntensity: 0.55,
        precipitationKind: SkyPrecipitationKind.rain,
        overcastFlattening: 0.4,
      );
    case WeatherCondition.snow:
    case WeatherCondition.snowShowers:
      return const _ConditionEffects(
        cloudCoverage: 0.8,
        precipitationIntensity: 0.45,
        precipitationKind: SkyPrecipitationKind.snow,
        overcastFlattening: 0.35,
      );
    case WeatherCondition.sleet:
    case WeatherCondition.freezingRain:
    case WeatherCondition.wintryMix:
      return const _ConditionEffects(
        cloudCoverage: 0.85,
        precipitationIntensity: 0.5,
        precipitationKind: SkyPrecipitationKind.snow,
        overcastFlattening: 0.4,
      );
    case WeatherCondition.thunderstorms:
      return const _ConditionEffects(
        cloudCoverage: 0.95,
        precipitationIntensity: 0.75,
        precipitationKind: SkyPrecipitationKind.rain,
        stormFlicker: true,
        overcastFlattening: 0.6,
      );
    case WeatherCondition.tornado:
    case WeatherCondition.hurricane:
    case WeatherCondition.tropicalStorm:
      return const _ConditionEffects(
        cloudCoverage: 1.0,
        precipitationIntensity: 0.9,
        precipitationKind: SkyPrecipitationKind.rain,
        stormFlicker: true,
        overcastFlattening: 0.75,
      );
    case WeatherCondition.windy:
      return const _ConditionEffects(cloudCoverage: 0.3);
    case WeatherCondition.hot:
      return const _ConditionEffects(cloudCoverage: 0.05);
    case WeatherCondition.cold:
      return const _ConditionEffects(cloudCoverage: 0.2);
    case WeatherCondition.unknown:
      return const _ConditionEffects(cloudCoverage: 0.3);
  }
}

const Color _overcastGray = Color(0xFF6B7280);

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

/// Resolves the full continuous [SkyPalette] for this instant.
///
/// [position] is the sun's actual continuous position (see
/// `solar_position.dart`) — the dominant input. [condition] modifies it
/// (clouds, precipitation, storms). [uiBrightness] only nudges saturation
/// within the resolved palette; it never changes whether the sky reads as
/// day or night (see the module doc below).
SkyPalette resolveSkyPalette({
  required SolarPosition position,
  required WeatherCondition condition,
  required Brightness uiBrightness,
}) {
  final elevation = position.elevationDegrees.clamp(
    _anchors.first.elevation,
    _anchors.last.elevation,
  );

  var lower = _anchors.first;
  var upper = _anchors.last;
  for (var i = 0; i < _anchors.length - 1; i++) {
    if (elevation >= _anchors[i].elevation && elevation <= _anchors[i + 1].elevation) {
      lower = _anchors[i];
      upper = _anchors[i + 1];
      break;
    }
  }
  final span = upper.elevation - lower.elevation;
  final t = span == 0 ? 0.0 : ((elevation - lower.elevation) / span).clamp(0.0, 1.0);

  var topColor = Color.lerp(lower.topColor, upper.topColor, t)!;
  var bottomColor = Color.lerp(lower.bottomColor, upper.bottomColor, t)!;
  var starOpacity = _lerpDouble(lower.starOpacity, upper.starOpacity, t);
  var glowIntensity = _lerpDouble(lower.horizonGlowIntensity, upper.horizonGlowIntensity, t);
  final glowColor = Color.lerp(lower.horizonGlowColor, upper.horizonGlowColor, t)!;

  final effects = _effectsFor(condition);

  // Clouds mute the underlying elevation-driven gradient toward flat
  // overcast gray, and block the horizon glow and stars proportionally.
  if (effects.overcastFlattening > 0) {
    topColor = Color.lerp(topColor, _overcastGray, effects.overcastFlattening)!;
    bottomColor = Color.lerp(bottomColor, _overcastGray, effects.overcastFlattening * 0.8)!;
  }
  glowIntensity *= (1 - effects.cloudCoverage * 0.85);
  starOpacity *= (1 - effects.cloudCoverage).clamp(0.0, 1.0);

  // uiBrightness nudges saturation/lightness within the family the
  // elevation+condition already chose — it never overrides day/night.
  if (uiBrightness == Brightness.light) {
    topColor = Color.lerp(topColor, Colors.white, 0.12)!;
    bottomColor = Color.lerp(bottomColor, Colors.white, 0.12)!;
  }

  final averageLuminance = (topColor.computeLuminance() + bottomColor.computeLuminance()) / 2;
  final heroContentBrightness = averageLuminance > 0.42 ? Brightness.light : Brightness.dark;

  // A third gradient stop, low in the sky, that only reads as a distinct
  // warm band within roughly 14 degrees of the horizon on either side —
  // real dawn/dusk skies have a visible warm layer between the zenith
  // color and the horizon glow itself, not just a straight blend between
  // the two. Clouds damp it along with everything else near the horizon.
  const midColorStop = 0.62;
  final naturalMidColor = Color.lerp(topColor, bottomColor, midColorStop)!;
  final sunriseBandWeight = (1 - (elevation.abs() / 14.0)).clamp(0.0, 1.0);
  final midBandStrength = sunriseBandWeight * (1 - effects.cloudCoverage * 0.7) * 0.5;
  final warmMidColor = Color.lerp(glowColor, Colors.white, 0.15)!;
  final midColor = Color.lerp(naturalMidColor, warmMidColor, midBandStrength)!;

  final sunMoonElevationFraction = ((position.elevationDegrees + 10) / 100).clamp(0.0, 1.0);
  final sunMoonVisibility = position.elevationDegrees > -4
      ? (1 - effects.cloudCoverage * 0.9).clamp(0.0, 1.0)
      : (1 - effects.cloudCoverage * 0.9).clamp(0.0, 1.0) * 0.9;

  return SkyPalette(
    topColor: topColor,
    bottomColor: bottomColor,
    midColor: midColor,
    midColorStop: midColorStop,
    starOpacity: starOpacity.clamp(0.0, 1.0),
    cloudOpacity: effects.cloudCoverage,
    cloudCoverageFraction: effects.cloudCoverage,
    horizonGlowColor: glowColor,
    horizonGlowIntensity: glowIntensity.clamp(0.0, 1.0),
    sunMoonVisibility: sunMoonVisibility,
    isSunVisible: position.elevationDegrees > -2,
    sunMoonElevationFraction: sunMoonElevationFraction,
    sunMoonAzimuthDegrees: position.azimuthDegrees,
    precipitationIntensity: effects.precipitationIntensity,
    precipitationKind: effects.precipitationIntensity > 0 ? effects.precipitationKind : SkyPrecipitationKind.none,
    stormFlicker: effects.stormFlicker,
    heroContentBrightness: heroContentBrightness,
  );
}
