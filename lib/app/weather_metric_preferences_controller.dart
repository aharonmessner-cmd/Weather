import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/weather_metric.dart';
import 'providers.dart';

/// Which secondary weather metrics the user wants shown on the Weather
/// screen — mirrors `ShowZmanimController`'s persistence shape (a
/// versioned SharedPreferences key, read synchronously in `build()`), but
/// for a set of [WeatherMetric] rather than a single bool.
///
/// A metric being in this set means "the user wants it, if the current
/// data actually has it" — see `WeatherDetailsGrid` for where that's
/// combined with availability. This controller only knows about the
/// preference, never about whether NWS/Pirate Weather currently has a
/// value for a given metric.
class WeatherMetricPreferencesController extends Notifier<Set<WeatherMetric>> {
  static const _key = 'weather_metric_preferences_v1';

  /// The first-run default — every metric the app already effectively
  /// showed stays on, matching the pre-preferences experience exactly.
  /// Availability (does the current fetch actually have a value) is
  /// always checked separately in `WeatherDetailsGrid`, which is what
  /// makes it safe to default everything, including UV Index, Visibility,
  /// Wind Gusts, and Last Hour Precipitation, to on here.
  static const Set<WeatherMetric> defaults = {...WeatherMetric.values};

  @override
  Set<WeatherMetric> build() {
    final raw = ref.watch(sharedPreferencesProvider).getStringList(_key);
    if (raw == null) return defaults;
    // A persisted *empty* list is a deliberate "I turned everything off"
    // choice and must be respected as-is, not treated as "no preference
    // saved yet" -- only a genuinely absent key falls back to defaults.
    return WeatherMetric.values.where((m) => raw.contains(m.name)).toSet();
  }

  bool isEnabled(WeatherMetric metric) => state.contains(metric);

  Future<void> setEnabled(WeatherMetric metric, bool enabled) async {
    final next = Set<WeatherMetric>.of(state);
    if (enabled) {
      next.add(metric);
    } else {
      next.remove(metric);
    }
    state = next;
    await ref.read(sharedPreferencesProvider).setStringList(_key, next.map((m) => m.name).toList());
  }
}

final weatherMetricPreferencesProvider =
    NotifierProvider<WeatherMetricPreferencesController, Set<WeatherMetric>>(
  WeatherMetricPreferencesController.new,
);
