import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/environment/widgets/sky_clouds.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required double coverage, required double opacity, double t = 0}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 800,
            child: SkyClouds(coverageFraction: coverage, opacity: opacity, animationSeconds: t),
          ),
        ),
      ),
    );
  }

  testWidgets('renders nothing for zero coverage', (tester) async {
    await pump(tester, coverage: 0, opacity: 1);
    expect(find.descendant(of: find.byType(SkyClouds), matching: find.byType(CustomPaint)), findsNothing);
  });

  testWidgets('renders nothing for zero opacity', (tester) async {
    await pump(tester, coverage: 0.5, opacity: 0);
    expect(find.descendant(of: find.byType(SkyClouds), matching: find.byType(CustomPaint)), findsNothing);
  });

  testWidgets('renders without throwing at low coverage', (tester) async {
    await pump(tester, coverage: 0.15, opacity: 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without throwing at full coverage', (tester) async {
    await pump(tester, coverage: 1.0, opacity: 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drifting to a later animationSeconds does not throw', (tester) async {
    await pump(tester, coverage: 0.6, opacity: 1, t: 0);
    await pump(tester, coverage: 0.6, opacity: 1, t: 500);
    await pump(tester, coverage: 0.6, opacity: 1, t: 100000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without throwing at a zero-size layout', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 0,
          height: 0,
          child: SkyClouds(coverageFraction: 0.6, opacity: 1),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
