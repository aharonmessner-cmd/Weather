import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/environment/sky_palette.dart';
import 'package:weather/environment/widgets/sky_precipitation_overlay.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required double intensity,
    SkyPrecipitationKind kind = SkyPrecipitationKind.none,
    bool stormFlicker = false,
    double t = 0,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 800,
            child: SkyPrecipitationOverlay(
              intensity: intensity,
              kind: kind,
              stormFlicker: stormFlicker,
              animationSeconds: t,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders nothing with zero intensity and no storm flicker', (tester) async {
    await pump(tester, intensity: 0);
    expect(
      find.descendant(of: find.byType(SkyPrecipitationOverlay), matching: find.byType(CustomPaint)),
      findsNothing,
    );
  });

  testWidgets('renders when storm flicker is enabled even with zero intensity', (tester) async {
    await pump(tester, intensity: 0, stormFlicker: true);
    expect(
      find.descendant(of: find.byType(SkyPrecipitationOverlay), matching: find.byType(CustomPaint)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('rain kind renders without throwing across a range of intensities', (tester) async {
    for (final intensity in [0.05, 0.3, 0.6, 0.9, 1.0]) {
      await pump(tester, intensity: intensity, kind: SkyPrecipitationKind.rain);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('snow kind renders without throwing across a range of intensities', (tester) async {
    for (final intensity in [0.05, 0.3, 0.6, 0.9, 1.0]) {
      await pump(tester, intensity: intensity, kind: SkyPrecipitationKind.snow);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('storm flicker across many animation ticks does not throw', (tester) async {
    for (var t = 0.0; t < 40; t += 0.25) {
      await pump(tester, intensity: 0.7, kind: SkyPrecipitationKind.rain, stormFlicker: true, t: t);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without throwing at a zero-size layout', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 0,
          height: 0,
          child: SkyPrecipitationOverlay(intensity: 0.5, kind: SkyPrecipitationKind.rain),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
