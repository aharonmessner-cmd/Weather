import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/utils/solar_position.dart';

void main() {
  group('computeSolarPosition', () {
    test('elevation at solar noon matches solarNoonElevationDegrees', () {
      const latitude = 38.8894; // Washington, DC
      const longitude = -77.0352;
      final date = DateTime.utc(2026, 6, 21);

      // Scan for the UTC hour where the hour angle is closest to zero
      // (solar noon for this longitude), then compare the elevation
      // there against the closed-form peak-elevation formula.
      DateTime bestTime = date;
      double bestAbsHourAngle = double.infinity;
      for (var hour = 0; hour < 24; hour++) {
        final t = DateTime.utc(2026, 6, 21, hour);
        final pos = computeSolarPosition(latitude: latitude, longitude: longitude, utcTime: t);
        if (pos.hourAngleDegrees.abs() < bestAbsHourAngle) {
          bestAbsHourAngle = pos.hourAngleDegrees.abs();
          bestTime = t;
        }
      }

      final noonPosition = computeSolarPosition(latitude: latitude, longitude: longitude, utcTime: bestTime);
      final expectedPeak = solarNoonElevationDegrees(latitude: latitude, utcDate: date);

      expect(noonPosition.elevationDegrees, closeTo(expectedPeak, 1.0));
    });

    test('hour angle sign distinguishes morning from afternoon', () {
      const latitude = 38.8894;
      const longitude = -77.0352;

      final morning = computeSolarPosition(
        latitude: latitude,
        longitude: longitude,
        utcTime: DateTime.utc(2026, 6, 21, 12), // ~8 AM local (UTC-4)
      );
      final afternoon = computeSolarPosition(
        latitude: latitude,
        longitude: longitude,
        utcTime: DateTime.utc(2026, 6, 21, 22), // ~6 PM local
      );

      expect(morning.isMorningSide, isTrue);
      expect(afternoon.isMorningSide, isFalse);
    });

    test('elevation is highest near local solar noon and lower at night', () {
      const latitude = 38.8894;
      const longitude = -77.0352;
      final date = DateTime.utc(2026, 6, 21);

      final midday = computeSolarPosition(latitude: latitude, longitude: longitude, utcTime: date.add(const Duration(hours: 16)));
      final midnight = computeSolarPosition(latitude: latitude, longitude: longitude, utcTime: date.add(const Duration(hours: 4)));

      expect(midday.elevationDegrees, greaterThan(40));
      expect(midnight.elevationDegrees, lessThan(-10));
    });

    test('azimuth stays within the documented 0-360 range', () {
      for (var hour = 0; hour < 24; hour++) {
        final pos = computeSolarPosition(
          latitude: 38.8894,
          longitude: -77.0352,
          utcTime: DateTime.utc(2026, 3, 15, hour),
        );
        expect(pos.azimuthDegrees, inInclusiveRange(0, 360));
      }
    });
  });

  group('solarNoonElevationDegrees', () {
    test('is higher in northern-hemisphere summer than winter at the same latitude', () {
      const latitude = 45.0;
      final summer = solarNoonElevationDegrees(latitude: latitude, utcDate: DateTime.utc(2026, 6, 21));
      final winter = solarNoonElevationDegrees(latitude: latitude, utcDate: DateTime.utc(2026, 12, 21));
      expect(summer, greaterThan(winter));
    });
  });
}
