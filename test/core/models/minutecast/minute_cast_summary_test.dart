import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:weather/core/models/minutecast/minute_cast_summary.dart';
import 'package:weather/core/models/minutecast/minute_precipitation_forecast.dart';

final _base = DateTime.utc(2026, 8, 11, 10, 38);

MinutePrecipitationForecast _minute(
  int offsetMinutes, {
  double? intensity,
  PrecipitationType type = PrecipitationType.rain,
}) {
  return MinutePrecipitationForecast(
    time: _base.add(Duration(minutes: offsetMinutes)),
    type: intensity != null && intensity > 0 ? type : PrecipitationType.none,
    intensityMmPerHour: intensity,
  );
}

/// [count] dry minutes, continuing the timeline from offset [from] —
/// callers building a trailing dry tail must pass the correct starting
/// offset, since each minute's `.time` is derived from its true offset
/// from `_base`, not its position within this particular list literal.
List<MinutePrecipitationForecast> _dryFor(int count, {int from = 0}) {
  return List.generate(count, (i) => _minute(from + i, intensity: 0));
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('empty minute list is dry', () {
    final summary = summarizeMinuteCast(const [], _base);
    expect(summary.state, MinuteCastState.dry);
    expect(summary.headline, 'Dry for the next hour');
    expect(summary.subtitle, isNull);
  });

  test('all-dry 60 minutes is dry', () {
    final minutes = _dryFor(60);
    final summary = summarizeMinuteCast(minutes, _base);
    expect(summary.state, MinuteCastState.dry);
    expect(summary.headline, 'Dry for the next hour');
  });

  group('approaching (currently dry, rain starts later)', () {
    test('starting in 13 min uses exact minute count', () {
      final minutes = [
        ..._dryFor(13),
        for (var i = 13; i < 60; i++) _minute(i, intensity: 1.0),
      ];
      final summary = summarizeMinuteCast(minutes, _base);
      expect(summary.state, MinuteCastState.approaching);
      expect(summary.headline, 'Rain starting in 13 min');
    });

    test('starting in 1 min collapses to "starting now"', () {
      final minutes = [
        _minute(0, intensity: 0),
        for (var i = 1; i < 60; i++) _minute(i, intensity: 1.0),
      ];
      final summary = summarizeMinuteCast(minutes, _base);
      expect(summary.headline, 'Rain starting now');
    });

    test('starting in exactly 2 min still collapses to "starting now" (the boundary)', () {
      final minutes = [
        ..._dryFor(2),
        for (var i = 2; i < 60; i++) _minute(i, intensity: 1.0),
      ];
      final summary = summarizeMinuteCast(minutes, _base);
      expect(summary.headline, 'Rain starting now');
    });

    test('starting in 3 min is past the "now" boundary and shows the exact count', () {
      final minutes = [
        ..._dryFor(3),
        for (var i = 3; i < 60; i++) _minute(i, intensity: 1.0),
      ];
      final summary = summarizeMinuteCast(minutes, _base);
      expect(summary.headline, 'Rain starting in 3 min');
    });

    test('snow uses the same phrasing structure', () {
      final minutes = [
        ..._dryFor(22),
        for (var i = 22; i < 60; i++) _minute(i, intensity: 1.0, type: PrecipitationType.snow),
      ];
      final summary = summarizeMinuteCast(minutes, _base);
      expect(summary.headline, 'Snow starting in 22 min');
    });

    test('subtitle shows the intensity/type and start-end range when both are known, in the given time zone', () {
      final minutes = [
        ..._dryFor(13),
        for (var i = 13; i < 46; i++) _minute(i, intensity: 1.0), // light rain 10:51-11:24
        ..._dryFor(60 - 46, from: 46),
      ];
      final summary = summarizeMinuteCast(minutes, _base, timeZone: 'America/New_York');
      expect(summary.headline, 'Rain starting in 13 min');
      // _base is 10:38 UTC == 6:38 AM EDT in August -- times are in the
      // *location's* zone, not raw UTC, and not the (unset) device zone.
      expect(summary.subtitle, 'Light rain · 6:51–7:24');
    });

    test('subtitle omits the end time when no confirmed end exists in the window', () {
      final minutes = [
        ..._dryFor(13),
        for (var i = 13; i < 60; i++) _minute(i, intensity: 1.0),
      ];
      final summary = summarizeMinuteCast(minutes, _base);
      expect(summary.subtitle, 'Light rain');
    });
  });

  group('currently precipitating', () {
    test('ending in 28 min after a confirmed 3-minute dry run', () {
      final minutes = [
        for (var i = 0; i < 28; i++) _minute(i, intensity: 1.0),
        ..._dryFor(60 - 28, from: 28),
      ];
      final summary = summarizeMinuteCast(minutes, _base);
      expect(summary.state, MinuteCastState.ending);
      expect(summary.headline, 'Rain ending in 28 min');
    });

    test('ending within 2 min collapses to "ending soon"', () {
      final minutes = [
        _minute(0, intensity: 1.0),
        _minute(1, intensity: 1.0),
        for (var i = 2; i < 60; i++) _minute(i, intensity: 0),
      ];
      final summary = summarizeMinuteCast(minutes, _base);
      expect(summary.headline, 'Rain ending soon');
    });

    test('a single noisy dry minute inside an active event does not trigger "ending"', () {
      final minutes = [
        for (var i = 0; i < 20; i++) _minute(i, intensity: 1.0),
        _minute(20, intensity: 0), // one noisy dry minute
        for (var i = 21; i < 50; i++) _minute(i, intensity: 1.0),
        ..._dryFor(10, from: 50),
      ];
      final summary = summarizeMinuteCast(minutes, _base);
      // The real (confirmed, 3-persistent) end is at minute 50, not 20.
      expect(summary.state, MinuteCastState.ending);
      expect(summary.headline, 'Rain ending in 50 min');
    });

    test('a dry run that is cut off by the end of the data before confirming 3 minutes does not count as ending', () {
      final minutes = [
        for (var i = 0; i < 58; i++) _minute(i, intensity: 1.0),
        _minute(58, intensity: 0),
        _minute(59, intensity: 0), // only 2 dry minutes before the data ends
      ];
      final summary = summarizeMinuteCast(minutes, _base);
      expect(summary.state, MinuteCastState.active);
      expect(summary.headline, 'Rain continuing for the next hour');
    });

    test('no dry run anywhere in the window: "continuing for the next hour"', () {
      final minutes = List.generate(60, (i) => _minute(i, intensity: 1.0));
      final summary = summarizeMinuteCast(minutes, _base);
      expect(summary.state, MinuteCastState.active);
      expect(summary.headline, 'Rain continuing for the next hour');
      expect(summary.subtitle, 'Light rain');
    });

    test('snow ending uses the same phrasing structure', () {
      final minutes = [
        for (var i = 0; i < 20; i++) _minute(i, intensity: 1.0, type: PrecipitationType.snow),
        ..._dryFor(40, from: 20),
      ];
      final summary = summarizeMinuteCast(minutes, _base);
      expect(summary.headline, 'Snow ending in 20 min');
    });

    test('mixed precipitation types use the dominant type across the active span', () {
      final minutes = [
        for (var i = 0; i < 5; i++) _minute(i, intensity: 1.0, type: PrecipitationType.snow),
        for (var i = 5; i < 30; i++) _minute(i, intensity: 1.0, type: PrecipitationType.rain),
        ..._dryFor(30, from: 30),
      ];
      final summary = summarizeMinuteCast(minutes, _base);
      // Rain dominates (25 of 30 wet minutes).
      expect(summary.headline, contains('Rain'));
    });
  });

  group('current-minute alignment against a possibly-stale snapshot', () {
    test('"minutes away" is computed relative to `now`, not the data\'s own first entry', () {
      // Data was generated as if minute 0 were 10:33 (5 minutes before
      // `_base`), but the caller passes the *real* current time (`_base`)
      // -- e.g. a 5-minute-old cached snapshot being displayed now.
      final staleBase = _base.subtract(const Duration(minutes: 5));
      final minutes = List.generate(60, (i) {
        final time = staleBase.add(Duration(minutes: i));
        // Rain starts at absolute minute 18 from staleBase, i.e. 13
        // minutes from `_base`.
        return MinutePrecipitationForecast(
          time: time,
          type: i >= 18 ? PrecipitationType.rain : PrecipitationType.none,
          intensityMmPerHour: i >= 18 ? 1.0 : 0,
        );
      });

      final summary = summarizeMinuteCast(minutes, _base);
      expect(summary.headline, 'Rain starting in 13 min');
    });
  });
}
