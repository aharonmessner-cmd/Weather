import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/models/minutecast/minute_cast.dart';
import 'package:weather/core/models/minutecast/minute_precipitation_forecast.dart';
import 'package:weather/core/repositories/minutecast_repository.dart';
import 'package:weather/core/services/minutecast/minutecast_config.dart';
import 'package:weather/core/services/minutecast/minutecast_exceptions.dart';
import 'package:weather/features/weather/application/minute_cast_controller.dart';

const _dc = Location(id: 'dc', name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);

MinuteCast _snapshot({required DateTime generatedAt}) {
  return MinuteCast(
    generatedAt: generatedAt,
    location: _dc,
    minutes: [
      MinutePrecipitationForecast(
        time: generatedAt,
        type: PrecipitationType.rain,
        probability: 0.8,
        intensityMmPerHour: 1.0,
      ),
    ],
    source: MinuteCastSource.pirateWeather,
  );
}

/// A repository test double mirroring `_FakeWeatherRepository` in
/// weather_controller_test.dart, driven entirely by these fields rather
/// than real Pirate Weather fixtures.
class _FakeMinuteCastRepository implements MinuteCastRepository {
  MinuteCast? cached;
  MinuteCast? nextFetch;
  Object? fetchError;
  int fetchCount = 0;

  @override
  Future<MinuteCast?> getCached(Location location) async => cached;

  @override
  Future<MinuteCast> fetchAndCache(Location location) async {
    fetchCount++;
    if (fetchError != null) throw fetchError!;
    return nextFetch!;
  }
}

void main() {
  late _FakeMinuteCastRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeMinuteCastRepository();
    container = ProviderContainer(overrides: [
      minuteCastRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  group('build (initial load)', () {
    test('with no cache, awaits the network fetch and returns MinuteCastAvailable', () async {
      final fresh = _snapshot(generatedAt: DateTime.now());
      repo.nextFetch = fresh;

      final result = await container.read(minuteCastControllerProvider(_dc).future);

      expect(result, isA<MinuteCastAvailable>());
      expect((result as MinuteCastAvailable).data, fresh);
      expect(repo.fetchCount, 1);
    });

    test('with a fresh cache present, returns it immediately without a network fetch', () async {
      final cached = _snapshot(generatedAt: DateTime.now());
      repo.cached = cached;

      final result = await container.read(minuteCastControllerProvider(_dc).future);

      expect(result, isA<MinuteCastAvailable>());
      expect((result as MinuteCastAvailable).data, cached);
      expect(repo.fetchCount, 0, reason: 'a cache within the refresh interval should not trigger a fetch');
    });

    test('with a cache older than the refresh interval, returns it as stale and refreshes quietly', () async {
      final cached = _snapshot(
        generatedAt: DateTime.now().subtract(MinuteCastConfig.refreshInterval + const Duration(minutes: 1)),
      );
      final fresh = _snapshot(generatedAt: DateTime.now());
      repo.cached = cached;
      repo.nextFetch = fresh;

      final result = await container.read(minuteCastControllerProvider(_dc).future);
      expect(result, isA<MinuteCastStale>());
      expect((result as MinuteCastStale).data, cached);

      await Future<void>.delayed(Duration.zero);
      final state = container.read(minuteCastControllerProvider(_dc));
      expect(state.value, isA<MinuteCastAvailable>());
      expect((state.value as MinuteCastAvailable).data, fresh);
    });

    test('with a cache older than maxCacheAge, ignores it and fetches fresh instead', () async {
      final tooOld = _snapshot(
        generatedAt: DateTime.now().subtract(MinuteCastConfig.maxCacheAge + const Duration(minutes: 1)),
      );
      final fresh = _snapshot(generatedAt: DateTime.now());
      repo.cached = tooOld;
      repo.nextFetch = fresh;

      final result = await container.read(minuteCastControllerProvider(_dc).future);

      expect(result, isA<MinuteCastAvailable>());
      expect((result as MinuteCastAvailable).data, fresh);
      expect(repo.fetchCount, 1);
    });

    test('with a cache older than maxCacheAge and a failed fetch, becomes unavailable(cacheTooOld)', () async {
      final tooOld = _snapshot(
        generatedAt: DateTime.now().subtract(MinuteCastConfig.maxCacheAge + const Duration(minutes: 1)),
      );
      repo.cached = tooOld;
      repo.fetchError = const MinuteCastNetworkException();

      final result = await container.read(minuteCastControllerProvider(_dc).future);

      expect(result, isA<MinuteCastUnavailable>());
      expect((result as MinuteCastUnavailable).reason, MinuteCastUnavailableReason.cacheTooOld);
    });

    test('with no cache and a failed fetch, becomes unavailable(temporaryError)', () async {
      repo.fetchError = const MinuteCastServerException(503);

      final result = await container.read(minuteCastControllerProvider(_dc).future);

      expect(result, isA<MinuteCastUnavailable>());
      expect((result as MinuteCastUnavailable).reason, MinuteCastUnavailableReason.temporaryError);
    });

    test('with no cache and a not-configured error, becomes unavailable(notConfigured)', () async {
      repo.fetchError = const MinuteCastNotConfiguredException();

      final result = await container.read(minuteCastControllerProvider(_dc).future);

      expect(result, isA<MinuteCastUnavailable>());
      expect((result as MinuteCastUnavailable).reason, MinuteCastUnavailableReason.notConfigured);
    });
  });

  group('ensureFresh()', () {
    test('is a no-op when the current data is already fresh', () async {
      final cached = _snapshot(generatedAt: DateTime.now());
      repo.cached = cached;
      await container.read(minuteCastControllerProvider(_dc).future);
      expect(repo.fetchCount, 0);

      await container.read(minuteCastControllerProvider(_dc).notifier).ensureFresh();

      expect(repo.fetchCount, 0);
    });

    test('refreshes when the current data is older than the refresh interval', () async {
      // No cache: build() goes straight through _fetchFresh, which returns
      // MinuteCastAvailable(data) regardless of the fetched data's own
      // age -- used here to get an already-stale-by-age value into state
      // without waiting on a real clock.
      final old = _snapshot(
        generatedAt: DateTime.now().subtract(MinuteCastConfig.refreshInterval + const Duration(minutes: 1)),
      );
      repo.nextFetch = old;
      await container.read(minuteCastControllerProvider(_dc).future);
      expect(repo.fetchCount, 1);

      final refreshed = _snapshot(generatedAt: DateTime.now());
      repo.nextFetch = refreshed;

      await container.read(minuteCastControllerProvider(_dc).notifier).ensureFresh();

      final state = container.read(minuteCastControllerProvider(_dc));
      expect((state.value as MinuteCastAvailable).data, refreshed);
      expect(repo.fetchCount, 2);
    });

    test('a failed background refresh leaves the previous data on screen without an error state', () async {
      final old = _snapshot(
        generatedAt: DateTime.now().subtract(MinuteCastConfig.refreshInterval + const Duration(minutes: 1)),
      );
      repo.nextFetch = old;
      await container.read(minuteCastControllerProvider(_dc).future);

      repo.fetchError = const MinuteCastNetworkException();
      await container.read(minuteCastControllerProvider(_dc).notifier).ensureFresh();

      final state = container.read(minuteCastControllerProvider(_dc));
      expect(state.hasValue, isTrue);
      expect(state.value, isA<MinuteCastAvailable>());
      expect((state.value as MinuteCastAvailable).data, old);
      expect(state.hasError, isFalse);
    });
  });

  group('failure isolation', () {
    test('a MinuteCast fetch failure does not throw out of the provider (weather screen stays intact)', () async {
      repo.fetchError = const MinuteCastServerException(500);

      await expectLater(container.read(minuteCastControllerProvider(_dc).future), completes);

      final state = container.read(minuteCastControllerProvider(_dc));
      expect(state.hasError, isFalse, reason: 'MinuteCast failures must resolve to MinuteCastUnavailable, never AsyncError');
    });
  });
}
