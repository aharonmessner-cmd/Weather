import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/current_conditions.dart';
import 'package:weather/core/models/weather_condition.dart';
import 'package:weather/environment/weather_environment.dart';
import 'package:weather/features/weather/presentation/widgets/weather_hero_section.dart';

const _lat = 38.8894;
const _lon = -77.0352;

Future<void> _pump(
  WidgetTester tester, {
  required CurrentConditions current,
  String locationName = 'Washington, DC',
  double textScale = 1.0,
  double width = 390,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: SizedBox(
              width: width,
              child: WeatherEnvironment(
                condition: WeatherCondition.clearSky,
                now: DateTime.utc(2026, 6, 20, 16),
                latitude: _lat,
                longitude: _lon,
                child: WeatherHeroSection(locationName: locationName, current: current),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

const _typical = CurrentConditions(
  temperatureFahrenheit: 78,
  condition: WeatherCondition.partlyCloudy,
  conditionText: 'Partly Cloudy',
  todayHighFahrenheit: 82,
  todayLowFahrenheit: 64,
);

void main() {
  testWidgets('renders location, temperature, condition text, and the H/L pill without throwing', (tester) async {
    await _pump(tester, current: _typical);

    expect(tester.takeException(), isNull);
    expect(find.text('Washington, DC'), findsOneWidget);
    expect(find.text('78'), findsOneWidget);
    expect(find.text('Partly Cloudy'), findsOneWidget);
    expect(find.text('82°'), findsOneWidget);
    expect(find.text('64°'), findsOneWidget);
  });

  testWidgets('omits the H/L pill when neither high nor low is available', (tester) async {
    await _pump(
      tester,
      current: const CurrentConditions(temperatureFahrenheit: 78, condition: WeatherCondition.clearSky),
    );

    expect(find.text('H'), findsNothing);
    expect(find.text('L'), findsNothing);
  });

  testWidgets('renders a long location name without overflowing (ellipsis, not a crash)', (tester) async {
    await _pump(
      tester,
      current: _typical,
      locationName: 'A Very Long Saved Location Name That Does Not Fit On One Line',
      width: 320,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('tolerates a large system text scale without overflowing', (tester) async {
    await _pump(tester, current: _typical, textScale: 2.0, width: 320);

    expect(tester.takeException(), isNull);
  });
}
