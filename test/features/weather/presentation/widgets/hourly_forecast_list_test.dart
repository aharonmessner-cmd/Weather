import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:weather/core/models/hourly_forecast.dart';
import 'package:weather/features/weather/presentation/widgets/hourly_forecast_list.dart';
import 'package:weather/theme/glass_style.dart';

// Regression coverage for the "hourly forecast jumps to 1PM/2PM" bug: the
// entries themselves were always correctly selected (see
// hourly_forecast_test.dart's upcomingFrom coverage) -- the actual defect
// was that the widget labeled each entry with its raw UTC hour instead of
// converting to the location's time zone. These tests pump the real widget
// and assert on the rendered label text, so a regression here fails loudly
// instead of hiding behind a passing model-layer test.

List<HourlyForecastEntry> _entriesFromUtcHours(List<int> utcHours) {
  return [
    for (final h in utcHours) HourlyForecastEntry(time: DateTime.utc(2026, 8, 11, h), temperatureFahrenheit: 75),
  ];
}

Future<void> _pump(WidgetTester tester, {required List<HourlyForecastEntry> entries, String? timeZone}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HourlyForecastList(
          entries: entries,
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
          timeZone: timeZone,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('HourlyForecastList time labels', () {
    testWidgets('labels entries in the location time zone, not raw UTC', (tester) async {
      // 15:00 UTC on 2026-08-11 is 11:00 AM EDT (America/New_York is
      // UTC-4 in August) -- the bug rendered "3PM" here (raw UTC hour).
      await _pump(tester, entries: _entriesFromUtcHours([15]), timeZone: 'America/New_York');

      expect(find.text('11AM'), findsOneWidget);
      expect(find.text('3PM'), findsNothing);
    });

    testWidgets('the same UTC instants label differently under a different location time zone', (tester) async {
      final entries = _entriesFromUtcHours([15]);

      await _pump(tester, entries: entries, timeZone: 'America/Los_Angeles');
      expect(find.text('8AM'), findsOneWidget); // PDT is UTC-7 in August

      await tester.pumpWidget(const SizedBox()); // unmount before repumping
      await _pump(tester, entries: entries, timeZone: 'America/New_York');
      expect(find.text('11AM'), findsOneWidget); // EDT is UTC-4 in August
    });

    testWidgets('consecutive hourly entries render exactly one hour apart, in order', (tester) async {
      // 14:38 UTC "now" -> next four upcoming hours would be 15:00..18:00
      // UTC, i.e. 11AM, 12PM, 1PM, 2PM in America/New_York (EDT, UTC-4).
      await _pump(tester, entries: _entriesFromUtcHours([15, 16, 17, 18]), timeZone: 'America/New_York');

      final labels = ['11AM', '12PM', '1PM', '2PM'];
      for (final label in labels) {
        expect(find.text(label), findsOneWidget, reason: 'expected a column labeled $label');
      }

      // Also assert left-to-right order matches chronological order, not
      // just presence -- catches an accidental re-sort or reversed list.
      final positions = [for (final label in labels) tester.getTopLeft(find.text(label)).dx];
      for (var i = 1; i < positions.length; i++) {
        expect(positions[i], greaterThan(positions[i - 1]));
      }
    });

    testWidgets('a null time zone falls back to device-local time without throwing', (tester) async {
      await _pump(tester, entries: _entriesFromUtcHours([15]));
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unrecognized time zone falls back gracefully without throwing', (tester) async {
      await _pump(tester, entries: _entriesFromUtcHours([15]), timeZone: 'Not/A_Real_Zone');
      expect(tester.takeException(), isNull);
    });
  });
}
