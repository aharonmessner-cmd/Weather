import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/features/weather/presentation/widgets/temperature_hero.dart';

void main() {
  Future<void> pump(WidgetTester tester, int? temperature, {double width = 360}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: TemperatureHero(temperatureFahrenheit: temperature, contentColor: Colors.white),
          ),
        ),
      ),
    );
  }

  testWidgets('exposes a full accessible label regardless of the stylized visual', (tester) async {
    await pump(tester, 72);

    expect(find.bySemanticsLabel('72 degrees Fahrenheit'), findsOneWidget);
  });

  testWidgets('reports temperature-unavailable when the value is null', (tester) async {
    await pump(tester, null);

    expect(find.bySemanticsLabel('Temperature unavailable'), findsOneWidget);
  });

  testWidgets('descendant text is excluded from the semantics tree (no duplicate raw-digit node)', (tester) async {
    await pump(tester, 72);

    final handle = tester.ensureSemantics();
    final rootNode = tester.getSemantics(find.byType(TemperatureHero));
    // excludeSemantics replaces descendants with the single explicit
    // label — the raw "72" Text's own semantics should not leak through
    // as a second, separate node underneath it.
    expect(rootNode.label, '72 degrees Fahrenheit');
    handle.dispose();
  });

  testWidgets('renders negative temperatures without throwing', (tester) async {
    await pump(tester, -5);
    expect(find.text('-5'), findsOneWidget);
    expect(find.bySemanticsLabel('-5 degrees Fahrenheit'), findsOneWidget);
  });

  testWidgets('scales up its font size on a wider layout without overflowing', (tester) async {
    await pump(tester, 72, width: 1000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scales down without overflowing on a very narrow layout', (tester) async {
    await pump(tester, 100, width: 120);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow with a three-digit temperature', (tester) async {
    await pump(tester, 104, width: 360);
    expect(tester.takeException(), isNull);
  });
}
