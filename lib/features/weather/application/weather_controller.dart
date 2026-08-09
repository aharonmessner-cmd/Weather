import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/models/location.dart';
import '../../../core/models/weather_data.dart';
import '../../../core/repositories/weather_repository.dart';

/// Drives the "cache immediately, refresh quietly" flow the weather
/// dashboard relies on: [build] returns whatever's cached for [location]
/// right away (if anything), then kicks off a network refresh in the
/// background and updates [state] when it lands. If there's no cache yet,
/// [build] awaits the network fetch directly, since there's nothing else to
/// show.
///
/// One instance exists per [Location] (via `.family`), so switching
/// locations doesn't lose each location's in-memory state.
class WeatherController extends AsyncNotifier<WeatherData> {
  WeatherController(this.location);

  final Location location;

  @override
  Future<WeatherData> build() async {
    final repo = ref.watch(weatherRepositoryProvider);
    final cached = await repo.getCached(location);
    if (cached == null) {
      return repo.fetchAndCache(location);
    }
    unawaited(_refreshQuietly(repo));
    return cached;
  }

  Future<void> _refreshQuietly(WeatherRepository repo) async {
    try {
      final fresh = await repo.fetchAndCache(location);
      if (ref.mounted) state = AsyncData(fresh);
    } catch (_) {
      // Cached data is already on screen; a manual refresh can surface the
      // error if the user asks for one.
    }
  }

  /// Fetches fresh data on demand (pull-to-refresh, a retry button).
  ///
  /// If we already have data to show, it stays on screen through a failed
  /// refresh — this rethrows so the caller (the UI) can surface a
  /// "couldn't refresh" message without blanking the screen.
  Future<void> refresh() async {
    final repo = ref.read(weatherRepositoryProvider);
    final previous = state.value;

    if (previous == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => repo.fetchAndCache(location));
      return;
    }

    try {
      final fresh = await repo.fetchAndCache(location);
      state = AsyncData(fresh);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final weatherControllerProvider = AsyncNotifierProvider.family<WeatherController, WeatherData, Location>(
  WeatherController.new,
);
