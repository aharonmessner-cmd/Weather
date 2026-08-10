import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/utils/day_phase.dart';
import 'package:weather/core/utils/solar_position.dart';

SolarPosition _positionAt({required double elevation, required bool morning}) {
  return SolarPosition(
    elevationDegrees: elevation,
    azimuthDegrees: morning ? 100 : 260,
    hourAngleDegrees: morning ? -30 : 30,
  );
}

void main() {
  group('computeDayPhase', () {
    const solarNoonElevation = 60.0; // a typical mid-latitude summer peak

    test('deep negative elevation on either side is night', () {
      expect(
        computeDayPhase(position: _positionAt(elevation: -40, morning: true), solarNoonElevationDegrees: solarNoonElevation),
        DayPhase.night,
      );
      expect(
        computeDayPhase(position: _positionAt(elevation: -40, morning: false), solarNoonElevationDegrees: solarNoonElevation),
        DayPhase.night,
      );
    });

    test('morning-side twilight is sunrise, afternoon-side twilight near the horizon is sunset', () {
      expect(
        computeDayPhase(position: _positionAt(elevation: -5, morning: true), solarNoonElevationDegrees: solarNoonElevation),
        DayPhase.sunrise,
      );
      expect(
        computeDayPhase(position: _positionAt(elevation: 1, morning: false), solarNoonElevationDegrees: solarNoonElevation),
        DayPhase.sunset,
      );
    });

    test('afternoon-side deeper twilight (below the horizon, above night) is evening', () {
      expect(
        computeDayPhase(position: _positionAt(elevation: -5, morning: false), solarNoonElevationDegrees: solarNoonElevation),
        DayPhase.evening,
      );
    });

    test('moderate elevation is morning or afternoon depending on side', () {
      expect(
        computeDayPhase(position: _positionAt(elevation: 20, morning: true), solarNoonElevationDegrees: solarNoonElevation),
        DayPhase.morning,
      );
      expect(
        computeDayPhase(position: _positionAt(elevation: 20, morning: false), solarNoonElevationDegrees: solarNoonElevation),
        DayPhase.afternoon,
      );
    });

    test("elevation near the day's peak is midday regardless of side", () {
      expect(
        computeDayPhase(position: _positionAt(elevation: 55, morning: true), solarNoonElevationDegrees: solarNoonElevation),
        DayPhase.midday,
      );
      expect(
        computeDayPhase(position: _positionAt(elevation: 55, morning: false), solarNoonElevationDegrees: solarNoonElevation),
        DayPhase.midday,
      );
    });

    test('a low winter peak still reaches midday near its own peak, not a fixed absolute angle', () {
      const winterPeak = 25.0;
      expect(
        computeDayPhase(position: _positionAt(elevation: 22, morning: true), solarNoonElevationDegrees: winterPeak),
        DayPhase.midday,
      );
    });
  });
}
