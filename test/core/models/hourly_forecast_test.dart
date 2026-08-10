import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/hourly_forecast.dart';

// Note: DateTime.parse normalizes an explicit-offset string (e.g.
// "-04:00") to this isolate's local timezone rather than preserving that
// offset, so asserting on `.hour` would be sensitive to whatever timezone
// happens to run the suite. Every assertion below instead compares full
// DateTime values (or day-of-month, for the midnight-crossing case) —
// equality/ordering between DateTimes is instant-based in Dart, so this
// is correct regardless of the runner's local timezone.
HourlyForecastEntry _entry(String iso8601, {int? temperatureFahrenheit}) {
  return HourlyForecastEntry(
    time: DateTime.parse(iso8601),
    temperatureFahrenheit: temperatureFahrenheit,
  );
}

void main() {
  group('HourlyForecastEntry.upcomingFrom', () {
    test('10:38 AM: excludes the in-progress 10 AM period, starts at 11 AM', () {
      final entries = [
        _entry('2026-08-09T10:00:00-04:00', temperatureFahrenheit: 78),
        _entry('2026-08-09T11:00:00-04:00', temperatureFahrenheit: 80),
        _entry('2026-08-09T12:00:00-04:00', temperatureFahrenheit: 82),
        _entry('2026-08-09T13:00:00-04:00', temperatureFahrenheit: 83),
        _entry('2026-08-09T14:00:00-04:00', temperatureFahrenheit: 84),
      ];
      final now = DateTime.parse('2026-08-09T10:38:00-04:00');

      final result = HourlyForecastEntry.upcomingFrom(entries, now);

      expect(result.map((e) => e.time), [
        DateTime.parse('2026-08-09T11:00:00-04:00'),
        DateTime.parse('2026-08-09T12:00:00-04:00'),
        DateTime.parse('2026-08-09T13:00:00-04:00'),
        DateTime.parse('2026-08-09T14:00:00-04:00'),
      ]);
      expect(result.first.temperatureFahrenheit, 80);
    });

    test('10:05 PM: excludes the in-progress 10 PM period, starts at 11 PM', () {
      final entries = [
        _entry('2026-08-09T22:00:00-04:00'),
        _entry('2026-08-09T23:00:00-04:00'),
        _entry('2026-08-10T00:00:00-04:00'),
        _entry('2026-08-10T01:00:00-04:00'),
      ];
      final now = DateTime.parse('2026-08-09T22:05:00-04:00');

      final result = HourlyForecastEntry.upcomingFrom(entries, now);

      expect(result.map((e) => e.time), [
        DateTime.parse('2026-08-09T23:00:00-04:00'),
        DateTime.parse('2026-08-10T00:00:00-04:00'),
        DateTime.parse('2026-08-10T01:00:00-04:00'),
      ]);
    });

    test('just before an hour boundary keeps the period that is about to start', () {
      final entries = [
        _entry('2026-08-09T10:00:00-04:00'),
        _entry('2026-08-09T11:00:00-04:00'),
      ];
      final now = DateTime.parse('2026-08-09T10:59:59-04:00');

      final result = HourlyForecastEntry.upcomingFrom(entries, now);

      expect(result.map((e) => e.time), [DateTime.parse('2026-08-09T11:00:00-04:00')]);
    });

    test('just after an hour boundary excludes the period that just started', () {
      final entries = [
        _entry('2026-08-09T11:00:00-04:00'),
        _entry('2026-08-09T12:00:00-04:00'),
      ];
      final now = DateTime.parse('2026-08-09T11:00:01-04:00');

      final result = HourlyForecastEntry.upcomingFrom(entries, now);

      expect(result.map((e) => e.time), [DateTime.parse('2026-08-09T12:00:00-04:00')]);
    });

    test('exactly on an hour boundary excludes that period (isAfter is strict)', () {
      final entries = [
        _entry('2026-08-09T11:00:00-04:00'),
        _entry('2026-08-09T12:00:00-04:00'),
      ];
      final now = DateTime.parse('2026-08-09T11:00:00-04:00');

      final result = HourlyForecastEntry.upcomingFrom(entries, now);

      expect(result.map((e) => e.time), [DateTime.parse('2026-08-09T12:00:00-04:00')]);
    });

    test('midnight crossing: 11:38 PM rolls into the next calendar day', () {
      final entries = [
        _entry('2026-08-09T23:00:00-04:00'),
        _entry('2026-08-10T00:00:00-04:00'),
        _entry('2026-08-10T01:00:00-04:00'),
      ];
      final now = DateTime.parse('2026-08-09T23:38:00-04:00');

      final result = HourlyForecastEntry.upcomingFrom(entries, now);

      expect(result, hasLength(2));
      expect(result[0].time, DateTime.parse('2026-08-10T00:00:00-04:00'));
      expect(result[1].time, DateTime.parse('2026-08-10T01:00:00-04:00'));
    });

    test('timezone conversion: entries and "now" in different UTC offsets still compare correctly', () {
      // Entries tagged in Eastern time (-04:00); "now" expressed in UTC.
      // 14:38 UTC is 10:38 AM Eastern, so this should behave identically to
      // the plain 10:38 AM case above even though nothing here shares an
      // offset literally.
      final entries = [
        _entry('2026-08-09T10:00:00-04:00'), // 14:00 UTC
        _entry('2026-08-09T11:00:00-04:00'), // 15:00 UTC
        _entry('2026-08-09T12:00:00-04:00'), // 16:00 UTC
      ];
      final now = DateTime.parse('2026-08-09T14:38:00Z');

      final result = HourlyForecastEntry.upcomingFrom(entries, now);

      expect(result.map((e) => e.time), [
        DateTime.parse('2026-08-09T11:00:00-04:00'),
        DateTime.parse('2026-08-09T12:00:00-04:00'),
      ]);
    });

    test('daylight-saving transition: comparison stays correct across an offset change', () {
      // NWS would represent a period before a DST transition with one UTC
      // offset and periods after it with another; the absolute instants
      // still order correctly even though the printed offset changes.
      final entries = [
        _entry('2026-11-01T00:30:00-04:00'), // EDT, 04:30 UTC
        _entry('2026-11-01T01:30:00-05:00'), // just after "fall back" to EST, 06:30 UTC
        _entry('2026-11-01T02:30:00-05:00'), // 07:30 UTC
      ];
      final now = DateTime.parse('2026-11-01T05:00:00Z'); // between the 1st and 2nd entries

      final result = HourlyForecastEntry.upcomingFrom(entries, now);

      expect(result, hasLength(2));
      expect(result[0].time, DateTime.parse('2026-11-01T01:30:00-05:00'));
      expect(result[1].time, DateTime.parse('2026-11-01T02:30:00-05:00'));
    });

    test('missing/irregular periods: a gap in NWS data is preserved, not fabricated', () {
      final entries = [
        _entry('2026-08-09T11:00:00-04:00'),
        // 12:00 and 13:00 missing entirely from the NWS response.
        _entry('2026-08-09T14:00:00-04:00'),
      ];
      final now = DateTime.parse('2026-08-09T10:00:00-04:00');

      final result = HourlyForecastEntry.upcomingFrom(entries, now);

      expect(result.map((e) => e.time), [
        DateTime.parse('2026-08-09T11:00:00-04:00'),
        DateTime.parse('2026-08-09T14:00:00-04:00'),
      ]);
    });

    test('out-of-order input is sorted ascending by time', () {
      final entries = [
        _entry('2026-08-09T13:00:00-04:00'),
        _entry('2026-08-09T11:00:00-04:00'),
        _entry('2026-08-09T12:00:00-04:00'),
      ];
      final now = DateTime.parse('2026-08-09T10:00:00-04:00');

      final result = HourlyForecastEntry.upcomingFrom(entries, now);

      expect(result.map((e) => e.time), [
        DateTime.parse('2026-08-09T11:00:00-04:00'),
        DateTime.parse('2026-08-09T12:00:00-04:00'),
        DateTime.parse('2026-08-09T13:00:00-04:00'),
      ]);
    });

    test('returns an empty list (not a crash) when every period has already elapsed', () {
      final entries = [
        _entry('2026-08-09T08:00:00-04:00'),
        _entry('2026-08-09T09:00:00-04:00'),
      ];
      final now = DateTime.parse('2026-08-09T12:00:00-04:00');

      expect(HourlyForecastEntry.upcomingFrom(entries, now), isEmpty);
    });

    test('returns an empty list for empty input', () {
      expect(HourlyForecastEntry.upcomingFrom(const [], DateTime.now()), isEmpty);
    });
  });
}
