import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:weather/core/utils/location_time.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('resolveLocationTime', () {
    test('converts a UTC instant to the given IANA zone', () {
      final instant = DateTime.utc(2026, 1, 15, 20, 30); // 20:30 UTC
      final result = resolveLocationTime(instant, 'America/New_York');

      // Mid-January -> EST (UTC-5).
      expect(result.hour, 15);
      expect(result.minute, 30);
    });

    test('correctly applies DST (EDT, UTC-4) in summer', () {
      final instant = DateTime.utc(2026, 7, 15, 20, 30);
      final result = resolveLocationTime(instant, 'America/New_York');

      expect(result.hour, 16);
      expect(result.minute, 30);
    });

    test('falls back to device-local time when timeZone is null', () {
      final instant = DateTime.utc(2026, 1, 15, 20, 30);
      final result = resolveLocationTime(instant, null);

      expect(result, instant.toLocal());
    });

    test('falls back to device-local time for an unrecognized zone name, rather than throwing', () {
      final instant = DateTime.utc(2026, 1, 15, 20, 30);
      final result = resolveLocationTime(instant, 'Not/A_Real_Zone');

      expect(result, instant.toLocal());
    });

    test('a different saved location can resolve to a different wall-clock hour than the device', () {
      final instant = DateTime.utc(2026, 1, 15, 4, 30); // e.g. device in UTC
      final nyResult = resolveLocationTime(instant, 'America/New_York');
      final laResult = resolveLocationTime(instant, 'America/Los_Angeles');

      expect(nyResult.hour, isNot(laResult.hour));
    });
  });

  group('formatClockTime', () {
    test('formats with AM/PM', () {
      expect(formatClockTime(DateTime.utc(2026, 1, 15, 20, 30), 'America/New_York'), '3:30 PM');
      expect(formatClockTime(DateTime.utc(2026, 1, 15, 5, 5), 'America/New_York'), '12:05 AM');
      expect(formatClockTime(DateTime.utc(2026, 1, 15, 17, 0), 'America/New_York'), '12:00 PM');
    });
  });

  group('formatClockHour', () {
    test('formats hour-only with AM/PM, no minutes', () {
      expect(formatClockHour(DateTime.utc(2026, 1, 15, 20, 45), 'America/New_York'), '3PM');
    });
  });

  group('formatClockTimeCompact', () {
    test('formats without AM/PM', () {
      expect(formatClockTimeCompact(DateTime.utc(2026, 1, 15, 20, 30), 'America/New_York'), '3:30');
      expect(formatClockTimeCompact(DateTime.utc(2026, 1, 15, 5, 5), 'America/New_York'), '12:05');
    });
  });
}
