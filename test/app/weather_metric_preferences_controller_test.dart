import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/app/weather_metric_preferences_controller.dart';
import 'package:weather/core/models/weather_metric.dart';

Future<ProviderContainer> _containerWithPrefs([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
}

void main() {
  group('defaults', () {
    test('every metric is enabled on first run (no persisted key)', () async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);

      expect(container.read(weatherMetricPreferencesProvider), WeatherMetricPreferencesController.defaults);
      expect(container.read(weatherMetricPreferencesProvider), WeatherMetric.values.toSet());
    });
  });

  group('setEnabled', () {
    test('disabling a metric removes only that metric', () async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);

      await container.read(weatherMetricPreferencesProvider.notifier).setEnabled(WeatherMetric.humidity, false);

      final state = container.read(weatherMetricPreferencesProvider);
      expect(state.contains(WeatherMetric.humidity), isFalse);
      expect(state, hasLength(WeatherMetric.values.length - 1));
    });

    test('re-enabling a disabled metric restores it', () async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      final notifier = container.read(weatherMetricPreferencesProvider.notifier);

      await notifier.setEnabled(WeatherMetric.wind, false);
      await notifier.setEnabled(WeatherMetric.wind, true);

      expect(container.read(weatherMetricPreferencesProvider).contains(WeatherMetric.wind), isTrue);
    });

    test('isEnabled reflects current state', () async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      final notifier = container.read(weatherMetricPreferencesProvider.notifier);

      expect(notifier.isEnabled(WeatherMetric.uvIndex), isTrue);
      await notifier.setEnabled(WeatherMetric.uvIndex, false);
      expect(notifier.isEnabled(WeatherMetric.uvIndex), isFalse);
    });
  });

  group('persistence', () {
    test('a change persists and survives a fresh container reading the same prefs', () async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await container.read(weatherMetricPreferencesProvider.notifier).setEnabled(WeatherMetric.dewPoint, false);

      final prefs = await SharedPreferences.getInstance();
      final reloaded = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(reloaded.dispose);

      expect(reloaded.read(weatherMetricPreferencesProvider).contains(WeatherMetric.dewPoint), isFalse);
    });

    test('a persisted empty list (everything disabled) is respected, not treated as "no preference"', () async {
      final container = await _containerWithPrefs({'weather_metric_preferences_v1': <String>[]});
      addTearDown(container.dispose);

      expect(container.read(weatherMetricPreferencesProvider), isEmpty);
    });

    test('unrecognized persisted metric names are dropped without crashing', () async {
      final container = await _containerWithPrefs({
        'weather_metric_preferences_v1': ['humidity', 'someFutureMetricThisVersionDoesNotKnow'],
      });
      addTearDown(container.dispose);

      expect(container.read(weatherMetricPreferencesProvider), {WeatherMetric.humidity});
    });
  });
}
