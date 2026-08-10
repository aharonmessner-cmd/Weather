import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/weather_alert.dart';
import 'package:weather/features/alerts/presentation/alert_detail_screen.dart';

const _alert = WeatherAlert(
  id: 'nws-1',
  event: 'Heat Advisory',
  severity: AlertSeverity.moderate,
  headline: 'Heat Advisory in effect until 8 PM EDT',
  description: 'Dangerously hot conditions expected.',
  instruction: 'Drink plenty of fluids and stay in air conditioning.',
  areaDesc: 'District of Columbia',
  senderName: 'NWS Baltimore/Washington',
);

void main() {
  Future<void> pump(WidgetTester tester, WeatherAlert alert) {
    return tester.pumpWidget(MaterialApp(home: AlertDetailScreen(alert: alert)));
  }

  testWidgets('renders event title, headline, area, description, and instructions', (tester) async {
    await pump(tester, _alert);

    expect(find.text('Heat Advisory'), findsWidgets); // app bar + body
    expect(find.text('Heat Advisory in effect until 8 PM EDT'), findsOneWidget);
    expect(find.text('District of Columbia'), findsOneWidget);
    expect(find.text('Dangerously hot conditions expected.'), findsOneWidget);
    expect(find.text('Drink plenty of fluids and stay in air conditioning.'), findsOneWidget);
    expect(find.text('NWS Baltimore/Washington'), findsOneWidget);
    expect(find.text('MODERATE'), findsOneWidget);
  });

  testWidgets('omits optional sections that are null without throwing', (tester) async {
    const sparse = WeatherAlert(id: 'nws-2', event: 'Small Craft Advisory', severity: AlertSeverity.minor);
    await pump(tester, sparse);

    expect(tester.takeException(), isNull);
    expect(find.text('Area'), findsNothing);
    expect(find.text('Details'), findsNothing);
    expect(find.text('Instructions'), findsNothing);
    expect(find.text('MINOR'), findsOneWidget);
  });

  testWidgets('shows effective/expires timing when present', (tester) async {
    final timed = _alert.copyWithTimes(
      effective: DateTime.utc(2026, 8, 10, 16),
      expires: DateTime.utc(2026, 8, 11, 0),
    );
    await pump(tester, timed);

    expect(find.text('Effective'), findsOneWidget);
    expect(find.text('Expires'), findsOneWidget);
  });
}

extension on WeatherAlert {
  WeatherAlert copyWithTimes({DateTime? effective, DateTime? expires}) {
    return WeatherAlert(
      id: id,
      event: event,
      severity: severity,
      headline: headline,
      description: description,
      instruction: instruction,
      areaDesc: areaDesc,
      senderName: senderName,
      effective: effective,
      expires: expires,
    );
  }
}
