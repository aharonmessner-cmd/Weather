import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/weather_condition.dart';
import 'package:weather/environment/sky_palette.dart';
import 'package:weather/environment/weather_environment.dart';

// Washington, DC.
const _lat = 38.8894;
const _lon = -77.0352;

Widget _harness({
  required ThemeMode themeMode,
  required DateTime now,
  required WeatherCondition condition,
  required Widget child,
}) {
  return MaterialApp(
    themeMode: themeMode,
    theme: ThemeData(brightness: Brightness.light),
    darkTheme: ThemeData(brightness: Brightness.dark),
    home: Scaffold(
      body: WeatherEnvironment(
        condition: condition,
        now: now,
        latitude: _lat,
        longitude: _lon,
        child: child,
      ),
    ),
  );
}

void main() {
  group('WeatherEnvironment', () {
    testWidgets('renders its child on top of the sky without throwing', (tester) async {
      await tester.pumpWidget(
        _harness(
          themeMode: ThemeMode.dark,
          now: DateTime.utc(2026, 6, 20, 16),
          condition: WeatherCondition.clearSky,
          child: const Text('hero content'),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('hero content'), findsOneWidget);
    });

    testWidgets('paletteOf exposes the resolved palette to descendants', (tester) async {
      late SkyPalette captured;
      await tester.pumpWidget(
        _harness(
          themeMode: ThemeMode.dark,
          now: DateTime.utc(2026, 6, 20, 16), // midday
          condition: WeatherCondition.clearSky,
          child: Builder(
            builder: (context) {
              captured = WeatherEnvironment.paletteOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured.heroContentBrightness, Brightness.light);
      expect(captured.starOpacity, lessThan(0.05));
    });

    testWidgets('paletteOf asserts when called with no WeatherEnvironment ancestor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              WeatherEnvironment.paletteOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    group('theme mode never determines day/night — only real sun position does', () {
      testWidgets('Light UI + nighttime still renders a dark, starry sky', (tester) async {
        late SkyPalette palette;
        await tester.pumpWidget(
          _harness(
            themeMode: ThemeMode.light,
            now: DateTime.utc(2026, 6, 20, 4), // ~midnight local (UTC-4)
            condition: WeatherCondition.clearSky,
            child: Builder(
              builder: (context) {
                palette = WeatherEnvironment.paletteOf(context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(palette.heroContentBrightness, Brightness.dark, reason: 'a night sky must read as dark content regardless of Light UI mode');
        expect(palette.starOpacity, greaterThan(0.5));
      });

      testWidgets('Dark UI + daytime still renders a bright, star-free sky', (tester) async {
        late SkyPalette palette;
        await tester.pumpWidget(
          _harness(
            themeMode: ThemeMode.dark,
            now: DateTime.utc(2026, 6, 20, 16), // midday local
            condition: WeatherCondition.clearSky,
            child: Builder(
              builder: (context) {
                palette = WeatherEnvironment.paletteOf(context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(palette.heroContentBrightness, Brightness.light, reason: 'a midday sky must read as light content regardless of Dark UI mode');
        expect(palette.starOpacity, lessThan(0.05));
      });

      testWidgets('Light UI + daytime and Dark UI + daytime agree on day/night, not just UI mode', (tester) async {
        final results = <ThemeMode, SkyPalette>{};
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          await tester.pumpWidget(
            _harness(
              themeMode: mode,
              now: DateTime.utc(2026, 6, 20, 16),
              condition: WeatherCondition.clearSky,
              child: Builder(
                builder: (context) {
                  results[mode] = WeatherEnvironment.paletteOf(context);
                  return const SizedBox();
                },
              ),
            ),
          );
        }

        expect(results[ThemeMode.light]!.heroContentBrightness, results[ThemeMode.dark]!.heroContentBrightness);
        expect(results[ThemeMode.light]!.isSunVisible, isTrue);
        expect(results[ThemeMode.dark]!.isSunVisible, isTrue);
      });

      testWidgets('Light UI + nighttime and Dark UI + nighttime agree on day/night, not just UI mode', (tester) async {
        final results = <ThemeMode, SkyPalette>{};
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          await tester.pumpWidget(
            _harness(
              themeMode: mode,
              now: DateTime.utc(2026, 6, 20, 4),
              condition: WeatherCondition.clearSky,
              child: Builder(
                builder: (context) {
                  results[mode] = WeatherEnvironment.paletteOf(context);
                  return const SizedBox();
                },
              ),
            ),
          );
        }

        expect(results[ThemeMode.light]!.heroContentBrightness, results[ThemeMode.dark]!.heroContentBrightness);
        expect(results[ThemeMode.light]!.isSunVisible, isFalse);
        expect(results[ThemeMode.dark]!.isSunVisible, isFalse);
      });
    });
  });
}
