import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/weather_condition.dart';
import 'package:weather/features/weather/presentation/widgets/weather_glyphs.dart';

void main() {
  Future<void> pump(WidgetTester tester, WeatherCondition condition, bool isDaytime) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeatherGlyph(condition: condition, isDaytime: isDaytime),
        ),
      ),
    );
  }

  for (final condition in WeatherCondition.values) {
    testWidgets('renders $condition (daytime) without throwing', (tester) async {
      await pump(tester, condition, true);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(WeatherGlyph), findsOneWidget);
    });

    testWidgets('renders $condition (nighttime) without throwing', (tester) async {
      await pump(tester, condition, false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(WeatherGlyph), findsOneWidget);
    });
  }

  testWidgets('honors an explicit color override', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WeatherGlyph(condition: WeatherCondition.clearSky, color: Colors.red),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
