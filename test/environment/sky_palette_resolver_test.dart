import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/weather_condition.dart';
import 'package:weather/core/utils/solar_position.dart';
import 'package:weather/environment/sky_palette_resolver.dart';

SolarPosition _position(double elevation, {double azimuth = 180, double hourAngle = 0}) {
  return SolarPosition(elevationDegrees: elevation, azimuthDegrees: azimuth, hourAngleDegrees: hourAngle);
}

void main() {
  group('resolveSkyPalette — day/night', () {
    test('deep night under clear skies shows strong stars and dark hero content brightness', () {
      final palette = resolveSkyPalette(
        position: _position(-70),
        condition: WeatherCondition.clearSky,
        uiBrightness: Brightness.dark,
      );
      expect(palette.starOpacity, greaterThan(0.8));
      expect(palette.heroContentBrightness, Brightness.dark);
      expect(palette.isSunVisible, isFalse);
    });

    test('high midday sun under clear skies shows no stars and light hero content brightness', () {
      final palette = resolveSkyPalette(
        position: _position(65),
        condition: WeatherCondition.clearSky,
        uiBrightness: Brightness.dark,
      );
      expect(palette.starOpacity, lessThan(0.05));
      expect(palette.heroContentBrightness, Brightness.light);
      expect(palette.isSunVisible, isTrue);
    });

    test('horizon glow peaks near the horizon and fades at both midday and deep night', () {
      final atHorizon = resolveSkyPalette(position: _position(0), condition: WeatherCondition.clearSky, uiBrightness: Brightness.dark);
      final midday = resolveSkyPalette(position: _position(60), condition: WeatherCondition.clearSky, uiBrightness: Brightness.dark);
      final night = resolveSkyPalette(position: _position(-70), condition: WeatherCondition.clearSky, uiBrightness: Brightness.dark);

      expect(atHorizon.horizonGlowIntensity, greaterThan(midday.horizonGlowIntensity));
      expect(atHorizon.horizonGlowIntensity, greaterThan(night.horizonGlowIntensity));
    });
  });

  group('resolveSkyPalette — continuity (no abrupt jumps)', () {
    test('two moments a fraction of a degree apart resolve to nearly identical colors', () {
      for (final elevation in [-70.0, -8.01, -8.0, -7.99, -3.0, -0.01, 0.0, 0.01, 6.0, 20.0]) {
        final a = resolveSkyPalette(position: _position(elevation), condition: WeatherCondition.clearSky, uiBrightness: Brightness.dark);
        final b = resolveSkyPalette(position: _position(elevation + 0.02), condition: WeatherCondition.clearSky, uiBrightness: Brightness.dark);

        expect(_colorDistance(a.topColor, b.topColor), lessThan(2),
            reason: 'topColor jumped near elevation $elevation°');
        expect(_colorDistance(a.bottomColor, b.bottomColor), lessThan(2),
            reason: 'bottomColor jumped near elevation $elevation°');
        expect((a.starOpacity - b.starOpacity).abs(), lessThan(0.02),
            reason: 'starOpacity jumped near elevation $elevation°');
        expect((a.horizonGlowIntensity - b.horizonGlowIntensity).abs(), lessThan(0.02),
            reason: 'horizonGlowIntensity jumped near elevation $elevation°');
      }
    });

    test('sweeping from night to midday changes the sky monotonically toward brighter, not back and forth', () {
      final elevations = [-90.0, -40.0, -18.0, -8.0, -3.0, 0.0, 6.0, 20.0, 60.0];
      final luminances = elevations
          .map((e) => resolveSkyPalette(position: _position(e), condition: WeatherCondition.clearSky, uiBrightness: Brightness.dark))
          .map((p) => (p.topColor.computeLuminance() + p.bottomColor.computeLuminance()) / 2)
          .toList();

      for (var i = 1; i < luminances.length; i++) {
        expect(luminances[i], greaterThanOrEqualTo(luminances[i - 1] - 0.01),
            reason: 'luminance decreased going from elevation ${elevations[i - 1]} to ${elevations[i]}');
      }
    });
  });

  group('resolveSkyPalette — weather condition effects', () {
    test('overcast mutes stars and horizon glow compared to clear skies at the same elevation', () {
      final clear = resolveSkyPalette(position: _position(-8), condition: WeatherCondition.clearSky, uiBrightness: Brightness.dark);
      final overcast = resolveSkyPalette(position: _position(-8), condition: WeatherCondition.overcast, uiBrightness: Brightness.dark);

      expect(overcast.starOpacity, lessThan(clear.starOpacity));
      expect(overcast.horizonGlowIntensity, lessThan(clear.horizonGlowIntensity));
      expect(overcast.cloudOpacity, greaterThan(clear.cloudOpacity));
    });

    test('thunderstorms carry a nonzero precipitation intensity and allow storm flicker', () {
      final palette = resolveSkyPalette(position: _position(20), condition: WeatherCondition.thunderstorms, uiBrightness: Brightness.dark);
      expect(palette.precipitationIntensity, greaterThan(0.5));
      expect(palette.stormFlicker, isTrue);
    });

    test('clear skies never trigger storm flicker or precipitation', () {
      final palette = resolveSkyPalette(position: _position(20), condition: WeatherCondition.clearSky, uiBrightness: Brightness.dark);
      expect(palette.stormFlicker, isFalse);
      expect(palette.precipitationIntensity, 0);
    });
  });

  group('resolveSkyPalette — uiBrightness nudges without overriding time-of-day', () {
    test('light UI brightness does not turn a clear midnight sky bright', () {
      final palette = resolveSkyPalette(position: _position(-70), condition: WeatherCondition.clearSky, uiBrightness: Brightness.light);
      expect(palette.heroContentBrightness, Brightness.dark);
      expect(palette.starOpacity, greaterThan(0.8));
    });

    test('dark UI brightness does not turn a clear midday sky dark', () {
      final palette = resolveSkyPalette(position: _position(65), condition: WeatherCondition.clearSky, uiBrightness: Brightness.dark);
      expect(palette.heroContentBrightness, Brightness.light);
      expect(palette.starOpacity, lessThan(0.05));
    });
  });
}

double _colorDistance(Color a, Color b) {
  final dr = (a.r - b.r) * 255;
  final dg = (a.g - b.g) * 255;
  final db = (a.b - b.b) * 255;
  return (dr.abs() + dg.abs() + db.abs()) / 3;
}
