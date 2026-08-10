import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/hourly_forecast.dart';
import 'package:weather/core/models/observation.dart';
import 'package:weather/core/models/weather_condition.dart';
import 'package:weather/core/utils/sun_times.dart';
import 'package:weather/features/weather/presentation/widgets/daily_forecast_list.dart';
import 'package:weather/features/weather/presentation/widgets/hourly_forecast_list.dart';
import 'package:weather/features/weather/presentation/widgets/info_metric_card.dart';
import 'package:weather/features/weather/presentation/widgets/precipitation_sparkline.dart';
import 'package:weather/features/weather/presentation/widgets/sunrise_arc_card.dart';
import 'package:weather/features/weather/presentation/widgets/weather_details_grid.dart';
import 'package:weather/features/weather/presentation/widgets/wind_compass_card.dart';
import 'package:weather/core/models/daily_forecast.dart';
import 'package:weather/theme/glass_style.dart';

Future<void> _pump(WidgetTester tester, Widget child, {double width = 400}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, child: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  group('InfoMetricCard', () {
    testWidgets('renders label and value without throwing', (tester) async {
      await _pump(
        tester,
        InfoMetricCard(
          icon: Icons.water_drop_outlined,
          label: 'Humidity',
          value: '54%',
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Humidity'), findsOneWidget);
      expect(find.text('54%'), findsOneWidget);
    });
  });

  group('WindCompassCard', () {
    testWidgets('renders with a known direction', (tester) async {
      await _pump(
        tester,
        WindCompassCard(
          speedMph: 12,
          directionDegrees: 225,
          directionCompass: 'SW',
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('renders gracefully with no wind data at all', (tester) async {
      await _pump(
        tester,
        const WindCompassCard(
          speedMph: null,
          directionDegrees: null,
          directionCompass: null,
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('No data'), findsOneWidget);
    });
  });

  group('SunriseArcCard', () {
    testWidgets('renders a normal day without throwing', (tester) async {
      final sunrise = DateTime.utc(2026, 6, 21, 10);
      final sunset = DateTime.utc(2026, 6, 21, 22);
      await _pump(
        tester,
        SunriseArcCard(
          sunTimes: SunTimes(sunrise: sunrise, sunset: sunset),
          now: sunrise.add(const Duration(hours: 4)),
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders polar day/night (no sunrise or sunset) without throwing', (tester) async {
      await _pump(
        tester,
        SunriseArcCard(
          sunTimes: const SunTimes(),
          now: DateTime.utc(2026, 6, 21),
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('--'), findsNWidgets(2));
    });

    testWidgets('exposes the sun\'s day-progress as a semantic label, since the arc has no text equivalent', (tester) async {
      final sunrise = DateTime.utc(2026, 6, 21, 10);
      final sunset = DateTime.utc(2026, 6, 21, 22); // 12h day
      await _pump(
        tester,
        SunriseArcCard(
          sunTimes: SunTimes(sunrise: sunrise, sunset: sunset),
          now: sunrise.add(const Duration(hours: 3)), // 25% through the day
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
      );

      expect(find.bySemanticsLabel('25 percent of the way from sunrise to sunset'), findsOneWidget);
    });

    testWidgets('describes unavailable sun position for polar day/night', (tester) async {
      await _pump(
        tester,
        SunriseArcCard(
          sunTimes: const SunTimes(),
          now: DateTime.utc(2026, 6, 21),
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
      );

      expect(find.bySemanticsLabel('Sun position unavailable'), findsOneWidget);
    });
  });

  group('PrecipitationSparkline', () {
    testWidgets('renders a mix of zero and non-zero probabilities without throwing', (tester) async {
      final base = DateTime(2026, 8, 9, 8);
      final entries = List.generate(
        6,
        (i) => HourlyForecastEntry(
          time: base.add(Duration(hours: i)),
          temperatureFahrenheit: 70 + i,
          precipitationProbabilityPercent: i.isEven ? 0 : 40,
        ),
      );
      await _pump(
        tester,
        PrecipitationSparkline(entries: entries, contentColor: Colors.white, style: GlassStyle.onSkyDark),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('hasSignal is false when every visible hour has no chance of precipitation', (tester) async {
      final base = DateTime(2026, 8, 9, 8);
      final entries = List.generate(
        4,
        (i) => HourlyForecastEntry(time: base.add(Duration(hours: i)), precipitationProbabilityPercent: 0),
      );
      expect(const PrecipitationSparkline(entries: [], contentColor: Colors.white, style: GlassStyle.onSkyDark)
          .hasSignal, isFalse);
      expect(
        PrecipitationSparkline(entries: entries, contentColor: Colors.white, style: GlassStyle.onSkyDark).hasSignal,
        isFalse,
      );
    });
  });

  group('HourlyForecastList', () {
    testWidgets('renders a populated list without throwing', (tester) async {
      final base = DateTime(2026, 8, 9, 8);
      final entries = List.generate(
        8,
        (i) => HourlyForecastEntry(
          time: base.add(Duration(hours: i)),
          temperatureFahrenheit: 70 + i,
          condition: WeatherCondition.partlyCloudy,
          precipitationProbabilityPercent: i.isEven ? 20 : 0,
        ),
      );
      await _pump(
        tester,
        HourlyForecastList(entries: entries, contentColor: Colors.white, style: GlassStyle.onSkyDark),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders an empty-state message when there is no data', (tester) async {
      await _pump(
        tester,
        const HourlyForecastList(entries: [], contentColor: Colors.white, style: GlassStyle.onSkyDark),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('No hourly forecast available.'), findsOneWidget);
    });
  });

  group('DailyForecastList', () {
    testWidgets('renders a populated list without throwing', (tester) async {
      final date = DateTime(2026, 8, 9);
      final entries = List.generate(
        5,
        (i) => DailyForecastEntry(
          date: date.add(Duration(days: i)),
          dayName: 'Day $i',
          condition: WeatherCondition.rain,
          highFahrenheit: 80 + i,
          lowFahrenheit: 60 + i,
          precipitationProbabilityPercent: i.isEven ? 30 : 0,
        ),
      );
      await _pump(
        tester,
        DailyForecastList(entries: entries, contentColor: Colors.white, style: GlassStyle.onSkyDark),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders an empty-state message when there is no data', (tester) async {
      await _pump(
        tester,
        const DailyForecastList(entries: [], contentColor: Colors.white, style: GlassStyle.onSkyDark),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('No daily forecast available.'), findsOneWidget);
    });
  });

  group('WeatherDetailsGrid', () {
    testWidgets('renders a fully-populated observation without throwing', (tester) async {
      final obs = Observation.fromJson({
        'observedAt': DateTime.now().toIso8601String(),
        'temperatureFahrenheit': 72.0,
        'humidityPercent': 54.0,
        'dewPointFahrenheit': 60.0,
        'windSpeedMph': 12.0,
        'windGustMph': 20.0,
        'windDirectionCompass': 'SW',
        'windDirectionDegrees': 225.0,
        'visibilityMiles': 10.0,
        'pressureInHg': 29.92,
        'precipitationLastHourInches': 0.1,
      });
      final base = DateTime(2026, 8, 9, 8);
      final hourly = List.generate(
        6,
        (i) => HourlyForecastEntry(time: base.add(Duration(hours: i)), precipitationProbabilityPercent: 30),
      );

      await _pump(
        tester,
        WeatherDetailsGrid(
          observation: obs,
          hourlyEntries: hourly,
          sunTimes: SunTimes(sunrise: base, sunset: base.add(const Duration(hours: 12))),
          now: base.add(const Duration(hours: 4)),
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a null observation as a message, not a crash', (tester) async {
      await _pump(
        tester,
        const WeatherDetailsGrid(observation: null, contentColor: Colors.white, style: GlassStyle.onSkyDark),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('No current observation available.'), findsOneWidget);
    });

    testWidgets('renders a sparse observation (no gusts, no precip, no sun times) without throwing', (tester) async {
      final obs = Observation.fromJson({
        'temperatureFahrenheit': 72.0,
      });
      await _pump(
        tester,
        WeatherDetailsGrid(observation: obs, contentColor: Colors.white, style: GlassStyle.onSkyDark),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('text scaling', () {
    Future<void> pumpScaled(WidgetTester tester, Widget child, double scale, {double width = 400}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: SizedBox(width: width, child: SingleChildScrollView(child: child)),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('the details grid tolerates a large system text scale without throwing', (tester) async {
      final obs = Observation.fromJson({
        'temperatureFahrenheit': 72.0,
        'humidityPercent': 54.0,
        'dewPointFahrenheit': 60.0,
        'windSpeedMph': 12.0,
        'windDirectionCompass': 'SW',
        'windDirectionDegrees': 225.0,
        'visibilityMiles': 10.0,
        'pressureInHg': 29.92,
      });
      final base = DateTime(2026, 8, 9, 8);
      final hourly = List.generate(
        6,
        (i) => HourlyForecastEntry(time: base.add(Duration(hours: i)), precipitationProbabilityPercent: 30),
      );

      await pumpScaled(
        tester,
        WeatherDetailsGrid(
          observation: obs,
          hourlyEntries: hourly,
          sunTimes: SunTimes(sunrise: base, sunset: base.add(const Duration(hours: 12))),
          now: base.add(const Duration(hours: 4)),
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
        2.0,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the hourly and daily forecast lists tolerate a large system text scale', (tester) async {
      final base = DateTime(2026, 8, 9, 8);
      final hourly = List.generate(
        8,
        (i) => HourlyForecastEntry(
          time: base.add(Duration(hours: i)),
          temperatureFahrenheit: 70 + i,
          condition: WeatherCondition.partlyCloudy,
          precipitationProbabilityPercent: i.isEven ? 20 : 0,
        ),
      );
      final daily = List.generate(
        5,
        (i) => DailyForecastEntry(
          date: DateTime(2026, 8, 9).add(Duration(days: i)),
          dayName: 'Day $i',
          condition: WeatherCondition.rain,
          highFahrenheit: 80 + i,
          lowFahrenheit: 60 + i,
          precipitationProbabilityPercent: i.isEven ? 30 : 0,
        ),
      );

      await pumpScaled(
        tester,
        Column(
          children: [
            HourlyForecastList(entries: hourly, contentColor: Colors.white, style: GlassStyle.onSkyDark),
            DailyForecastList(entries: daily, contentColor: Colors.white, style: GlassStyle.onSkyDark),
          ],
        ),
        1.6,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
