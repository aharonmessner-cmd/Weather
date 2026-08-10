import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/weather_alert.dart';
import 'package:weather/features/alerts/presentation/widgets/alert_card.dart';

void main() {
  const alert = WeatherAlert(
    id: 'alert-1',
    event: 'Heat Advisory',
    severity: AlertSeverity.moderate,
    areaDesc: 'District of Columbia; Arlington, VA',
  );

  Future<void> pump(WidgetTester tester, {Color? contentColor}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlertCard(alert: alert, contentColor: contentColor),
        ),
      ),
    );
  }

  testWidgets('renders using the ambient theme color by default', (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Heat Advisory'), findsOneWidget);
    expect(find.text('MODERATE'), findsOneWidget);
  });

  testWidgets('renders using an explicit contentColor override without throwing', (tester) async {
    await pump(tester, contentColor: Colors.white);
    expect(tester.takeException(), isNull);

    final titleText = tester.widget<Text>(find.text('Heat Advisory'));
    expect(titleText.style?.color, Colors.white);
  });
}
