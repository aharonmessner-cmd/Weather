import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/daily_forecast.dart';
import 'package:weather/core/models/nws/nws_forecast_period.dart';

import '../../support/fixture.dart';

void main() {
  group('DailyForecastEntry.fromNwsPeriods', () {
    test('pairs day/night periods into one entry per calendar date', () {
      final json = loadFixture('forecast.json');
      final forecast = NwsForecast.tryParse(json)!;
      final daily = DailyForecastEntry.fromNwsPeriods(forecast.periods);

      // 4 periods (Today, Tonight, Monday, Monday Night) -> 2 calendar days.
      expect(daily, hasLength(2));

      final today = daily[0];
      expect(today.dayName, 'This Afternoon');
      expect(today.highFahrenheit, 91);
      expect(today.lowFahrenheit, 72);
      expect(today.precipitationProbabilityPercent, 40);

      final monday = daily[1];
      expect(monday.dayName, 'Monday');
      expect(monday.highFahrenheit, 88);
      expect(monday.lowFahrenheit, 68);
      // Day period's probability was null; night's was 10 -> max of the two.
      expect(monday.precipitationProbabilityPercent, 10);
    });

    test('handles a forecast that starts mid-night with no preceding day period', () {
      final nightOnly = NwsForecastPeriod.tryParse({
        'name': 'Tonight',
        'startTime': '2026-08-09T20:00:00-04:00',
        'endTime': '2026-08-10T06:00:00-04:00',
        'isDaytime': false,
        'temperature': 65,
      })!;

      final daily = DailyForecastEntry.fromNwsPeriods([nightOnly]);
      expect(daily, hasLength(1));
      expect(daily.first.highFahrenheit, isNull);
      expect(daily.first.lowFahrenheit, 65);
      expect(daily.first.dayName, 'Tonight');
    });

    test('returns an empty list for an empty periods list', () {
      expect(DailyForecastEntry.fromNwsPeriods(const []), isEmpty);
    });

    test('falls back to a weekday name when no period name is present', () {
      final period = NwsForecastPeriod.tryParse({
        'startTime': '2026-08-12T06:00:00-04:00',
        'endTime': '2026-08-12T18:00:00-04:00',
        'isDaytime': true,
        'temperature': 80,
      })!;
      final daily = DailyForecastEntry.fromNwsPeriods([period]);
      expect(daily.single.dayName, 'Wednesday');
    });
  });
}
