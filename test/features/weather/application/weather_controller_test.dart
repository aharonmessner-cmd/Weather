import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/models/current_conditions.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/models/weather_data.dart';
import 'package:weather/core/repositories/weather_repository.dart';
import 'package:weather/core/services/nws/nws_exceptions.dart';
import 'package:weather/features/weather/application/weather_controller.dart';

const _dc = Location(id: 'dc', name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);

WeatherData _snapshot({required DateTime fetchedAt, double? tempF}) {
  return WeatherData(
    location: _dc,
    current: CurrentConditions(temperatureFahrenheit: tempF),
    fetchedAt: fetchedAt,
  );
}

/// A repository test double: [getCached] and [fetchAndCache] are driven
/// entirely by the fields below rather than going through NWS fixtures, so
/// these tests can exercise WeatherController's cache/refresh state
/// transitions directly and fast.
class _FakeWeatherRepository implements WeatherRepository {
  WeatherData? cached;
  WeatherData? nextFetch;
  Object? fetchError;
  int fetchCount = 0;

  /// Optional gate a test can use to hold [fetchAndCache] pending, to
  /// simulate a fetch that's still in flight.
  Future<void> Function()? beforeFetch;

  @override
  Future<WeatherData?> getCached(Location location) async => cached;

  @override
  Future<WeatherData> fetchAndCache(Location location) async {
    fetchCount++;
    if (beforeFetch != null) await beforeFetch!();
    if (fetchError != null) throw fetchError!;
    return nextFetch!;
  }
}

void main() {
  late _FakeWeatherRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeWeatherRepository();
    container = ProviderContainer(overrides: [
      weatherRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  group('build (initial load)', () {
    test('with no cache, awaits the network fetch directly', () async {
      final fresh = _snapshot(fetchedAt: DateTime.utc(2026, 8, 10, 12), tempF: 80);
      repo.nextFetch = fresh;

      final result = await container.read(weatherControllerProvider(_dc).future);

      expect(result, fresh);
      expect(repo.fetchCount, 1);
    });

    test('with a cache present, returns cached data immediately then refreshes quietly', () async {
      final cached = _snapshot(fetchedAt: DateTime.utc(2026, 8, 10, 11), tempF: 78);
      final fresh = _snapshot(fetchedAt: DateTime.utc(2026, 8, 10, 12), tempF: 81);
      repo.cached = cached;
      repo.nextFetch = fresh;

      final result = await container.read(weatherControllerProvider(_dc).future);
      expect(result, cached, reason: 'the cached snapshot is returned without waiting on the network');

      // The quiet background refresh is fire-and-forget; give it a turn.
      await Future<void>.delayed(Duration.zero);
      final state = container.read(weatherControllerProvider(_dc));
      expect(state.value, fresh);
    });

    test('a failed quiet refresh leaves the cached data on screen without an error state', () async {
      final cached = _snapshot(fetchedAt: DateTime.utc(2026, 8, 10, 11), tempF: 78);
      repo.cached = cached;
      repo.fetchError = const NwsNetworkException('offline');

      final result = await container.read(weatherControllerProvider(_dc).future);
      expect(result, cached);

      await Future<void>.delayed(Duration.zero);
      final state = container.read(weatherControllerProvider(_dc));
      expect(state.hasValue, isTrue);
      expect(state.value, cached);
      expect(state.hasError, isFalse);
    });
  });

  group('refresh()', () {
    test('with existing data, a successful refresh replaces it', () async {
      final cached = _snapshot(fetchedAt: DateTime.utc(2026, 8, 10, 11), tempF: 78);
      final fresh = _snapshot(fetchedAt: DateTime.utc(2026, 8, 10, 13), tempF: 90);
      repo.cached = cached;
      repo.nextFetch = fresh;
      await container.read(weatherControllerProvider(_dc).future);
      await Future<void>.delayed(Duration.zero); // let the initial quiet refresh land

      repo.nextFetch = fresh.copyWith(current: const CurrentConditions(temperatureFahrenheit: 95));
      await container.read(weatherControllerProvider(_dc).notifier).refresh();

      final state = container.read(weatherControllerProvider(_dc));
      expect(state.value!.current.temperatureFahrenheit, 95);
    });

    test('with existing data, a failed refresh keeps the previous data and rethrows', () async {
      final cached = _snapshot(fetchedAt: DateTime.utc(2026, 8, 10, 11), tempF: 78);
      repo.cached = cached;
      repo.nextFetch = cached;
      await container.read(weatherControllerProvider(_dc).future);
      await Future<void>.delayed(Duration.zero);

      repo.fetchError = const NwsNetworkException('offline');
      await expectLater(
        container.read(weatherControllerProvider(_dc).notifier).refresh(),
        throwsA(isA<NwsNetworkException>()),
      );

      final state = container.read(weatherControllerProvider(_dc));
      expect(state.value, cached);
      expect(state.hasError, isFalse, reason: 'previous data must stay on screen, not be replaced by an error state');
    });

    test('called before the initial build resolves, goes through a loading state then resolves', () async {
      // Exercises refresh()'s "no previous value yet" branch by calling it
      // while the initial build's fetch is still in flight (state is
      // AsyncLoading with no value), rather than via a failed initial
      // build — AsyncNotifier's built-in retry-on-error makes a genuinely
      // failed build's `.future` non-deterministic to await directly in a
      // test.
      final buildGate = Completer<void>();
      repo.beforeFetch = () => buildGate.future;
      final initialFetch = _snapshot(fetchedAt: DateTime.utc(2026, 8, 10, 12), tempF: 70);
      repo.nextFetch = initialFetch;

      final notifier = container.read(weatherControllerProvider(_dc).notifier);
      expect(container.read(weatherControllerProvider(_dc)).value, isNull);

      repo.beforeFetch = null;
      final refreshFuture = notifier.refresh();
      expect(container.read(weatherControllerProvider(_dc)).isLoading, isTrue);
      await refreshFuture;
      buildGate.complete();
      await Future<void>.delayed(Duration.zero); // let the original (now-unblocked) build settle too

      expect(container.read(weatherControllerProvider(_dc)).value, initialFetch);
    });
  });

  test('separate locations get independent controller instances', () async {
    const camp = Location(id: 'camp', name: 'Camp Runamuck', latitude: 44.2, longitude: -71.5);
    final dcData = _snapshot(fetchedAt: DateTime.utc(2026, 8, 10, 12), tempF: 80);
    repo.nextFetch = dcData;
    await container.read(weatherControllerProvider(_dc).future);

    final campData = _snapshot(fetchedAt: DateTime.utc(2026, 8, 10, 12), tempF: 60);
    repo.nextFetch = campData;
    await container.read(weatherControllerProvider(camp).future);

    expect(container.read(weatherControllerProvider(_dc)).value, dcData);
    expect(container.read(weatherControllerProvider(camp)).value, campData);
  });
}
