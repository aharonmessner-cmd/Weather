import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/environment/widgets/sky_stars.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required double opacity, double t = 0}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 800,
            child: SkyStars(opacity: opacity, animationSeconds: t),
          ),
        ),
      ),
    );
  }

  testWidgets('renders nothing when opacity is effectively zero', (tester) async {
    await pump(tester, opacity: 0);
    expect(find.descendant(of: find.byType(SkyStars), matching: find.byType(CustomPaint)), findsNothing);
  });

  testWidgets('renders without throwing at full opacity', (tester) async {
    await pump(tester, opacity: 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('twinkle phase advancing over time does not throw', (tester) async {
    for (final t in [0.0, 0.25, 3.7, 60.0, 3600.5]) {
      await pump(tester, opacity: 0.8, t: t);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without throwing at a zero-size layout', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 0, height: 0, child: SkyStars(opacity: 1)),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
