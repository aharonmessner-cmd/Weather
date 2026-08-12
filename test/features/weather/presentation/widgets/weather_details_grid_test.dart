import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/models/daily_forecast.dart';
import 'package:weather/core/models/hourly_forecast.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/models/minutecast/minute_cast.dart';
import 'package:weather/core/models/minutecast/minute_precipitation_forecast.dart';
import 'package:weather/core/models/observation.dart';
import 'package:weather/core/models/weather_condition.dart';
import 'package:weather/core/models/weather_metric.dart';
import 'package:weather/core/repositories/minutecast_repository.dart';
import 'package:weather/core/utils/sun_times.dart';
import 'package:weather/features/weather/presentation/widgets/daily_forecast_list.dart';
import 'package:weather/features/weather/presentation/widgets/hourly_forecast_list.dart';
import 'package:weather/features/weather/presentation/widgets/info_metric_card.dart';
import 'package:weather/features/weather/presentation/widgets/precipitation_sparkline.dart';
import 'package:weather/features/weather/presentation/widgets/sunrise_arc_card.dart';
import 'package:weather/features/weather/presentation/widgets/weather_details_grid.dart';
import 'package:weather/features/weather/presentation/widgets/wind_compass_card.dart';
import 'package:weather/theme/glass_style.dart';

const _dc = Location(id: 'dc', name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);

class _FakeMinuteCastRepository implements MinuteCastRepository {
  _FakeMinuteCastRepository({this.cached});

  MinuteCast? cached;

  @override
  Future<MinuteCast?> getCached(Location location) async => cached;

  @override
  Future<MinuteCast> fetchAndCache(Location location) async {
    if (cached != null) return cached!;
    throw StateError('no fake fetch configured');
  }
}

MinuteCast _minuteCastWithUv(double uv) {
  return MinuteCast(
    generatedAt: DateTime.now(),
    location: _dc,
    minutes: [MinutePrecipitationForecast(time: DateTime.now(), type: PrecipitationType.none)],
    source: MinuteCastSource.pirateWeather,
    uvIndex: uv,
  );
}

Observation _observation({
  double? humidityPercent,
  double? dewPointFahrenheit,
  double? pressureInHg,
  double? visibilityMiles,
  double? windSpeedMph,
  double? windGustMph,
  double? precipitationLastHourInches,
}) {
  return Observation(
    temperatureFahrenheit: 72,
    humidityPercent: humidityPercent,
    dewPointFahrenheit: dewPointFahrenheit,
    pressureInHg: pressureInHg,
    visibilityMiles: visibilityMiles,
    windSpeedMph: windSpeedMph,
    windGustMph: windGustMph,
    precipitationLastHourInches: precipitationLastHourInches,
  );
}

Future<void> _pump(WidgetTester tester, Widget child, {double width = 400}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, child: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

/// [WeatherDetailsGrid] reads Riverpod providers (metric preferences, and
/// MinuteCast for UV Index) -- these tests only need SharedPreferences
/// mocked; with no `--dart-define` API key set, MinuteCast resolves to
/// "not configured" immediately, with no real network call.
Future<void> _pumpGrid(
  WidgetTester tester,
  Widget child, {
  double width = 400,
  List overrides = const [],
  Map<String, Object> prefsValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs), ...overrides.cast()],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, child: SingleChildScrollView(child: child)),
        ),
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

    testWidgets('shows a gust line when gustMph is provided', (tester) async {
      await _pump(
        tester,
        WindCompassCard(
          speedMph: 12,
          directionDegrees: 225,
          directionCompass: 'SW',
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
          gustMph: 24,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Gusts 24 mph'), findsOneWidget);
    });

    testWidgets('omits the gust line when gustMph is null', (tester) async {
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
      expect(find.textContaining('Gusts'), findsNothing);
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

      await _pumpGrid(
        tester,
        WeatherDetailsGrid(
          observation: obs,
          location: _dc,
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
      await _pumpGrid(
        tester,
        const WeatherDetailsGrid(observation: null, location: _dc, contentColor: Colors.white, style: GlassStyle.onSkyDark),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('No current observation available.'), findsOneWidget);
    });

    testWidgets('renders a sparse observation (no gusts, no precip, no sun times) without throwing', (tester) async {
      final obs = Observation.fromJson({
        'temperatureFahrenheit': 72.0,
      });
      await _pumpGrid(
        tester,
        WeatherDetailsGrid(observation: obs, location: _dc, contentColor: Colors.white, style: GlassStyle.onSkyDark),
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

    Future<void> pumpScaledGrid(WidgetTester tester, Widget child, double scale, {double width = 400}) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: SizedBox(width: width, child: SingleChildScrollView(child: child)),
                ),
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

      await pumpScaledGrid(
        tester,
        WeatherDetailsGrid(
          location: _dc,
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

  group('enabled x available composition', () {
    Future<void> pumpWith(
      WidgetTester tester, {
      required Observation observation,
      required Set<WeatherMetric> enabledMetrics,
      MinuteCast? minuteCast,
      double width = 400,
    }) {
      return _pumpGrid(
        tester,
        WeatherDetailsGrid(observation: observation, location: _dc, contentColor: Colors.white, style: GlassStyle.onSkyDark),
        width: width,
        prefsValues: {
          'weather_metric_preferences_v1': [for (final m in enabledMetrics) m.name],
        },
        overrides: [
          minuteCastRepositoryProvider.overrideWithValue(_FakeMinuteCastRepository(cached: minuteCast)),
        ],
      );
    }

    testWidgets('enabled + available -> displayed (Humidity)', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(humidityPercent: 54),
        enabledMetrics: {WeatherMetric.humidity},
      );
      await tester.pumpAndSettle();

      expect(find.text('Humidity'), findsOneWidget);
    });

    testWidgets('enabled + unavailable -> hidden (Humidity, no data)', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(),
        enabledMetrics: {WeatherMetric.humidity},
      );
      await tester.pumpAndSettle();

      expect(find.text('Humidity'), findsNothing);
    });

    testWidgets('disabled + available -> hidden (Humidity present in data but off)', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(humidityPercent: 54),
        enabledMetrics: const {},
      );
      await tester.pumpAndSettle();

      expect(find.text('Humidity'), findsNothing);
    });

    testWidgets('disabled + unavailable -> hidden (Humidity)', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(),
        enabledMetrics: const {},
      );
      await tester.pumpAndSettle();

      expect(find.text('Humidity'), findsNothing);
    });

    testWidgets('disabling Humidity leaves other enabled metrics displayed (reflow, no gap)', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(dewPointFahrenheit: 60, pressureInHg: 29.92),
        enabledMetrics: {WeatherMetric.dewPoint, WeatherMetric.pressure},
      );
      await tester.pumpAndSettle();

      expect(find.text('Humidity'), findsNothing);
      expect(find.text('Dew Point'), findsOneWidget);
      expect(find.text('Pressure'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Visibility: enabled + available shows, disabled hides', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(visibilityMiles: 10),
        enabledMetrics: {WeatherMetric.visibility},
      );
      await tester.pumpAndSettle();
      expect(find.text('Visibility'), findsOneWidget);

      await pumpWith(
        tester,
        observation: _observation(visibilityMiles: 10),
        enabledMetrics: const {},
      );
      await tester.pumpAndSettle();
      expect(find.text('Visibility'), findsNothing);
    });

    testWidgets('Visibility: enabled but no data -> hidden, no "--" placeholder', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(),
        enabledMetrics: {WeatherMetric.visibility},
      );
      await tester.pumpAndSettle();

      expect(find.text('Visibility'), findsNothing);
      expect(find.text('--'), findsNothing);
    });

    testWidgets('Last Hour Precipitation: enabled + available shows, disabled hides', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(precipitationLastHourInches: 0.1),
        enabledMetrics: {WeatherMetric.lastHourPrecipitation},
      );
      await tester.pumpAndSettle();
      expect(find.text('Last Hour'), findsOneWidget);

      await pumpWith(
        tester,
        observation: _observation(precipitationLastHourInches: 0.1),
        enabledMetrics: const {},
      );
      await tester.pumpAndSettle();
      expect(find.text('Last Hour'), findsNothing);
    });

    testWidgets('Wind Gusts: shown as a line inside the wind compass card, not a separate tile', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(windSpeedMph: 12, windGustMph: 24),
        enabledMetrics: {WeatherMetric.wind, WeatherMetric.windGusts},
      );
      await tester.pumpAndSettle();

      expect(find.byType(WindCompassCard), findsOneWidget);
      expect(find.text('Gusts 24 mph'), findsOneWidget);
      // Gusts never gets its own InfoMetricCard tile.
      expect(find.widgetWithText(InfoMetricCard, 'Gusts'), findsNothing);
    });

    testWidgets('Wind Gusts: wind enabled but gusts disabled -> no gust line', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(windSpeedMph: 12, windGustMph: 24),
        enabledMetrics: {WeatherMetric.wind},
      );
      await tester.pumpAndSettle();

      expect(find.byType(WindCompassCard), findsOneWidget);
      expect(find.text('Gusts 24 mph'), findsNothing);
    });

    testWidgets('Wind Gusts: enabled but no gust data -> no gust line, no crash', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(windSpeedMph: 12),
        enabledMetrics: {WeatherMetric.wind, WeatherMetric.windGusts},
      );
      await tester.pumpAndSettle();

      expect(find.byType(WindCompassCard), findsOneWidget);
      expect(find.textContaining('Gusts'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Feels Like: enabled + available shows, disabled hides', (tester) async {
      await _pumpGrid(
        tester,
        WeatherDetailsGrid(
          observation: _observation(),
          location: _dc,
          feelsLikeFahrenheit: 75,
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
        prefsValues: {
          'weather_metric_preferences_v1': [WeatherMetric.feelsLike.name],
        },
      );
      await tester.pumpAndSettle();
      expect(find.text('Feels Like'), findsOneWidget);

      await _pumpGrid(
        tester,
        WeatherDetailsGrid(
          observation: _observation(),
          location: _dc,
          feelsLikeFahrenheit: 75,
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
        prefsValues: {'weather_metric_preferences_v1': <String>[]},
      );
      await tester.pumpAndSettle();
      expect(find.text('Feels Like'), findsNothing);
    });

    testWidgets('Feels Like: enabled but no data -> hidden, no "--" placeholder', (tester) async {
      await _pumpGrid(
        tester,
        WeatherDetailsGrid(
          observation: _observation(),
          location: _dc,
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
        prefsValues: {
          'weather_metric_preferences_v1': [WeatherMetric.feelsLike.name],
        },
      );
      await tester.pumpAndSettle();

      expect(find.text('Feels Like'), findsNothing);
    });

    testWidgets('UV Index: enabled + Pirate Weather has a value -> shown with category', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(),
        enabledMetrics: {WeatherMetric.uvIndex},
        minuteCast: _minuteCastWithUv(5),
      );
      await tester.pumpAndSettle();

      expect(find.text('UV Index'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
    });

    testWidgets('UV Index: enabled but unavailable (not configured / no cache) -> hidden, never N/A', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(),
        enabledMetrics: {WeatherMetric.uvIndex},
        minuteCast: null,
      );
      await tester.pumpAndSettle();

      expect(find.text('UV Index'), findsNothing);
      expect(find.textContaining('N/A'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('UV Index: available but disabled -> hidden', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(),
        enabledMetrics: const {},
        minuteCast: _minuteCastWithUv(8),
      );
      await tester.pumpAndSettle();

      expect(find.text('UV Index'), findsNothing);
    });

    testWidgets('UV Index unavailable never breaks the rest of the weather screen', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(humidityPercent: 40, dewPointFahrenheit: 55, pressureInHg: 30.1),
        enabledMetrics: {WeatherMetric.uvIndex, WeatherMetric.humidity, WeatherMetric.dewPoint, WeatherMetric.pressure},
        minuteCast: null,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Humidity'), findsOneWidget);
      expect(find.text('Dew Point'), findsOneWidget);
      expect(find.text('Pressure'), findsOneWidget);
      expect(find.text('UV Index'), findsNothing);
    });

    testWidgets('Wind: disabled hides WindCompassCard and reflows Sunrise to full width', (tester) async {
      final base = DateTime(2026, 8, 9, 8);
      await _pumpGrid(
        tester,
        WeatherDetailsGrid(
          observation: _observation(),
          location: _dc,
          sunTimes: SunTimes(sunrise: base, sunset: base.add(const Duration(hours: 12))),
          now: base.add(const Duration(hours: 4)),
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
        prefsValues: {'weather_metric_preferences_v1': <String>[]},
      );
      await tester.pumpAndSettle();

      expect(find.byType(WindCompassCard), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Precipitation: disabled hides the sparkline even when hourly entries have signal', (tester) async {
      final base = DateTime(2026, 8, 9, 8);
      final hourly = List.generate(
        6,
        (i) => HourlyForecastEntry(time: base.add(Duration(hours: i)), precipitationProbabilityPercent: 40),
      );
      await _pumpGrid(
        tester,
        WeatherDetailsGrid(
          observation: _observation(),
          location: _dc,
          hourlyEntries: hourly,
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
        prefsValues: {'weather_metric_preferences_v1': <String>[]},
      );
      await tester.pumpAndSettle();

      expect(find.byType(PrecipitationSparkline), findsNothing);
    });

    testWidgets('all metrics enabled and available renders without overflow at narrow width', (tester) async {
      final base = DateTime(2026, 8, 9, 8);
      final hourly = List.generate(
        6,
        (i) => HourlyForecastEntry(time: base.add(Duration(hours: i)), precipitationProbabilityPercent: 40),
      );
      await _pumpGrid(
        tester,
        WeatherDetailsGrid(
          observation: Observation.fromJson({
            'temperatureFahrenheit': 72.0,
            'humidityPercent': 54.0,
            'dewPointFahrenheit': 60.0,
            'windSpeedMph': 12.0,
            'windGustMph': 18.0,
            'windDirectionCompass': 'SW',
            'windDirectionDegrees': 225.0,
            'visibilityMiles': 10.0,
            'pressureInHg': 29.92,
            'precipitationLastHourInches': 0.05,
          }),
          location: _dc,
          feelsLikeFahrenheit: 75,
          hourlyEntries: hourly,
          sunTimes: SunTimes(sunrise: base, sunset: base.add(const Duration(hours: 12))),
          now: base.add(const Duration(hours: 4)),
          contentColor: Colors.white,
          style: GlassStyle.onSkyDark,
        ),
        width: 320,
        overrides: [
          minuteCastRepositoryProvider.overrideWithValue(_FakeMinuteCastRepository(cached: _minuteCastWithUv(6))),
        ],
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('UV Index'), findsOneWidget);
      expect(find.text('Feels Like'), findsOneWidget);
    });

    testWidgets('only a few metrics enabled renders a smaller grid without empty cells', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(humidityPercent: 54),
        enabledMetrics: {WeatherMetric.humidity},
      );
      await tester.pumpAndSettle();

      // Visibility is part of the configurable set too, so with only
      // Humidity enabled the grid holds exactly Humidity -- nothing else,
      // and no gap for the disabled Visibility/Dew Point/Pressure/etc.
      expect(find.byType(InfoMetricCard), findsNWidgets(1));
      expect(find.text('Humidity'), findsOneWidget);
      expect(find.text('Visibility'), findsNothing);
      expect(find.text('Dew Point'), findsNothing);
      expect(find.text('Pressure'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a narrow phone width (280) without overflow', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(humidityPercent: 54, dewPointFahrenheit: 60, pressureInHg: 29.92),
        enabledMetrics: {WeatherMetric.humidity, WeatherMetric.dewPoint, WeatherMetric.pressure, WeatherMetric.uvIndex},
        minuteCast: _minuteCastWithUv(9),
        width: 280,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a normal phone width (400) with a 2-column grid', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(humidityPercent: 54, dewPointFahrenheit: 60, pressureInHg: 29.92),
        enabledMetrics: {WeatherMetric.humidity, WeatherMetric.dewPoint, WeatherMetric.pressure},
        width: 400,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    });

    testWidgets('renders a tablet/desktop width (700) with a 3-column grid, no overflow', (tester) async {
      await pumpWith(
        tester,
        observation: _observation(humidityPercent: 54, dewPointFahrenheit: 60, pressureInHg: 29.92),
        enabledMetrics: {WeatherMetric.humidity, WeatherMetric.dewPoint, WeatherMetric.pressure, WeatherMetric.uvIndex},
        minuteCast: _minuteCastWithUv(3),
        width: 700,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    });
  });
}
