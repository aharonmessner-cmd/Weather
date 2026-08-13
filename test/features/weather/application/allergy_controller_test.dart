import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/models/allergy/allergy_data.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/repositories/allergy_repository.dart';
import 'package:weather/core/services/allergy/allergy_config.dart';
import 'package:weather/core/services/allergy/allergy_exceptions.dart';
import 'package:weather/features/weather/application/allergy_controller.dart';

const _dc = Location(id: 'dc', name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);

AllergyData _snapshot({required DateTime generatedAt, double? dust = 10}) {
  return AllergyData(
    generatedAt: generatedAt,
    location: _dc,
    source: AllergySource.openMeteo,
    dustMicrogramsPerCubicMeter: dust,
  );
}

/// A repository test double mirroring `_FakeMinuteCastRepository` in
/// minute_cast_controller_test.dart, driven entirely by these fields
/// rather than a real Open-Meteo fixture.
class _FakeAllergyRepository implements AllergyRepository {
  AllergyData? cached;
  AllergyData? nextFetch;
  Object? fetchError;
  int fetchCount = 0;

  @override
  Future<AllergyData?> getCached(Location location) async => cached;

  @override
  Future<AllergyData> fetchAndCache(Location location) async {
    fetchCount++;
    if (fetchError != null) throw fetchError!;
    return nextFetch!;
  }
}

void main() {
  late _FakeAllergyRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeAllergyRepository();
    container = ProviderContainer(overrides: [
      allergyRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  group('build (initial load)', () {
    test('with no cache, awaits the network fetch and returns AllergyAvailable', () async {
      final fresh = _snapshot(generatedAt: DateTime.now());
      repo.nextFetch = fresh;

      final result = await container.read(allergyControllerProvider(_dc).future);

      expect(result, isA<AllergyAvailable>());
      expect((result as AllergyAvailable).data, fresh);
      expect(repo.fetchCount, 1);
    });

    test('with a fresh cache present, returns it immediately without a network fetch', () async {
      final cached = _snapshot(generatedAt: DateTime.now());
      repo.cached = cached;

      final result = await container.read(allergyControllerProvider(_dc).future);

      expect(result, isA<AllergyAvailable>());
      expect((result as AllergyAvailable).data, cached);
      expect(repo.fetchCount, 0, reason: 'a cache within the refresh interval should not trigger a fetch');
    });

    test('with a cache older than the refresh interval, returns it as stale and refreshes quietly', () async {
      final cached = _snapshot(
        generatedAt: DateTime.now().subtract(AllergyConfig.refreshInterval + const Duration(minutes: 1)),
      );
      final fresh = _snapshot(generatedAt: DateTime.now());
      repo.cached = cached;
      repo.nextFetch = fresh;

      final result = await container.read(allergyControllerProvider(_dc).future);
      expect(result, isA<AllergyStale>());
      expect((result as AllergyStale).data, cached);

      await Future<void>.delayed(Duration.zero);
      final state = container.read(allergyControllerProvider(_dc));
      expect(state.value, isA<AllergyAvailable>());
      expect((state.value as AllergyAvailable).data, fresh);
    });

    test('with a cache older than maxCacheAge, ignores it and fetches fresh instead', () async {
      final tooOld = _snapshot(
        generatedAt: DateTime.now().subtract(AllergyConfig.maxCacheAge + const Duration(minutes: 1)),
      );
      final fresh = _snapshot(generatedAt: DateTime.now());
      repo.cached = tooOld;
      repo.nextFetch = fresh;

      final result = await container.read(allergyControllerProvider(_dc).future);

      expect(result, isA<AllergyAvailable>());
      expect((result as AllergyAvailable).data, fresh);
      expect(repo.fetchCount, 1);
    });

    test('with a cache older than maxCacheAge and a failed fetch, becomes unavailable(cacheTooOld)', () async {
      final tooOld = _snapshot(
        generatedAt: DateTime.now().subtract(AllergyConfig.maxCacheAge + const Duration(minutes: 1)),
      );
      repo.cached = tooOld;
      repo.fetchError = const AllergyNetworkException();

      final result = await container.read(allergyControllerProvider(_dc).future);

      expect(result, isA<AllergyUnavailable>());
      expect((result as AllergyUnavailable).reason, AllergyUnavailableReason.cacheTooOld);
    });

    test('with no cache and a failed fetch, becomes unavailable(temporaryError)', () async {
      repo.fetchError = const AllergyServerException(503);

      final result = await container.read(allergyControllerProvider(_dc).future);

      expect(result, isA<AllergyUnavailable>());
      expect((result as AllergyUnavailable).reason, AllergyUnavailableReason.temporaryError);
    });
  });

  group('failure isolation', () {
    test('an Allergy fetch failure does not throw out of the provider (weather screen stays intact)', () async {
      repo.fetchError = const AllergyServerException(500);

      await expectLater(container.read(allergyControllerProvider(_dc).future), completes);

      final state = container.read(allergyControllerProvider(_dc));
      expect(state.hasError, isFalse, reason: 'Allergy failures must resolve to AllergyUnavailable, never AsyncError');
    });
  });
}
