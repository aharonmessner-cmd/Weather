import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:weather/core/models/minutecast/minute_precipitation_forecast.dart';
import 'package:weather/features/weather/presentation/widgets/minutecast_timeline_painter.dart';

DateTime _base() => DateTime.utc(2026, 8, 11, 15, 0);

List<MinutePrecipitationForecast> _minutes(
  int count, {
  int wetFrom = -1,
  int wetTo = -1,
  PrecipitationType type = PrecipitationType.rain,
  double intensity = 1.5,
}) {
  return [
    for (var i = 0; i < count; i++)
      MinutePrecipitationForecast(
        time: _base().add(Duration(minutes: i)),
        type: i >= wetFrom && i < wetTo ? type : PrecipitationType.none,
        probability: i >= wetFrom && i < wetTo ? 0.7 : 0.0,
        intensityMmPerHour: i >= wetFrom && i < wetTo ? intensity : 0.0,
      ),
  ];
}

Future<void> _pump(
  WidgetTester tester, {
  required List<MinutePrecipitationForecast> minutes,
  DateTime? now,
  double width = 360,
  double textScale = 1.0,
  String? timeZone,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: SizedBox(
              width: width,
              child: MinuteCastTimeline(
                minutes: minutes,
                now: now ?? _base(),
                contentColor: Colors.white,
                timeZone: timeZone,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('MinuteCastTimeline', () {
    testWidgets('renders a fully dry timeline without throwing', (tester) async {
      await _pump(tester, minutes: _minutes(60));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders precipitation already active at the first minute (no leading taper) without throwing', (tester) async {
      await _pump(tester, minutes: _minutes(60, wetFrom: 0, wetTo: 20));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders precipitation continuing through the last minute (no trailing taper) without throwing', (tester) async {
      await _pump(tester, minutes: _minutes(60, wetFrom: 40, wetTo: 60));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders an interior precipitation run (tapered both sides) without throwing', (tester) async {
      await _pump(tester, minutes: _minutes(60, wetFrom: 10, wetTo: 30));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders snow (with its dotted texture) without throwing', (tester) async {
      await _pump(tester, minutes: _minutes(60, wetFrom: 5, wetTo: 45, type: PrecipitationType.snow));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders mixed rain/snow runs without throwing', (tester) async {
      final rainPart = _minutes(20, wetFrom: 5, wetTo: 15, type: PrecipitationType.rain);
      final mixed = [
        ...rainPart,
        for (var i = 20; i < 40; i++)
          MinutePrecipitationForecast(
            time: _base().add(Duration(minutes: i)),
            type: i >= 25 && i < 35 ? PrecipitationType.snow : PrecipitationType.none,
            probability: i >= 25 && i < 35 ? 0.6 : 0.0,
            intensityMmPerHour: i >= 25 && i < 35 ? 3.0 : 0.0,
          ),
      ];
      await _pump(tester, minutes: mixed);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles a degenerate single-minute list without throwing', (tester) async {
      await _pump(tester, minutes: _minutes(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on a narrow phone width without throwing or overflowing', (tester) async {
      await _pump(tester, minutes: _minutes(60, wetFrom: 10, wetTo: 40), width: 280);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders at a large text scale factor without throwing or overflowing', (tester) async {
      await _pump(tester, minutes: _minutes(60, wetFrom: 10, wetTo: 40), width: 320, textScale: 3.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clamps the NOW marker when now is before the data window without throwing', (tester) async {
      await _pump(
        tester,
        minutes: _minutes(60, wetFrom: 0, wetTo: 20),
        now: _base().subtract(const Duration(minutes: 5)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('clamps the NOW marker when now is after the data window without throwing', (tester) async {
      await _pump(
        tester,
        minutes: _minutes(60, wetFrom: 0, wetTo: 20),
        now: _base().add(const Duration(minutes: 90)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders location-timezone-aware compact time labels', (tester) async {
      await _pump(tester, minutes: _minutes(60), timeZone: 'America/New_York');
      expect(tester.takeException(), isNull);
      // 15:00 UTC on 2026-08-11 is 11:00 EDT -- the first label should
      // reflect the location's zone, not raw UTC or the test host's zone.
      expect(find.text('11:00'), findsOneWidget);
    });

    testWidgets('exposes a single decorative semantics node for the graphic, not per-pixel semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, minutes: _minutes(60, wetFrom: 10, wetTo: 30));

      expect(find.bySemanticsLabel('Precipitation intensity over the next hour, graphic'), findsOneWidget);
      handle.dispose();
    });
  });
}
