import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/app/zmanim_settings_controller.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/models/zmanim/hebcal_zman_field.dart';
import 'package:weather/core/models/zmanim/zmanim.dart';
import 'package:weather/core/repositories/zmanim_repository.dart';
import 'package:weather/core/services/zmanim/zmanim_exceptions.dart';
import 'package:weather/features/weather/application/zmanim_controller.dart';

const _dc = Location(id: 'dc', name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);
const _tz = 'America/New_York';

Zmanim _snapshot({String locationDate = '2026-08-11'}) {
  return Zmanim(
    locationDate: locationDate,
    location: _dc,
    generatedAt: DateTime.now(),
    times: {
      HebcalZmanField.sunrise: DateTime.parse('2026-08-11T06:08:00-04:00'),
      HebcalZmanField.sunset: DateTime.parse('2026-08-11T19:58:00-04:00'),
    },
  );
}

class _FakeZmanimRepository implements ZmanimRepository {
  Zmanim? cached;
  Zmanim? nextFetch;
  Object? fetchError;
  int fetchCount = 0;

  @override
  Future<Zmanim?> getCached(Location location, String timeZone) async => cached;

  @override
  Future<Zmanim> fetchAndCache(Location location, String timeZone) async {
    fetchCount++;
    if (fetchError != null) throw fetchError!;
    return nextFetch!;
  }
}

void main() {
  late _FakeZmanimRepository repo;
  late ProviderContainer container;

  setUp(() async {
    repo = _FakeZmanimRepository();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [
      zmanimRepositoryProvider.overrideWithValue(repo),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
  });

  tearDown(() => container.dispose());

  ZmanimQuery query({String? timeZone = _tz}) => (location: _dc, timeZone: timeZone);

  group('build', () {
    test('with a null time zone, becomes unavailable(noLocationTimeZone) without touching the repository', () async {
      final result = await container.read(zmanimControllerProvider(query(timeZone: null)).future);

      expect(result, isA<ZmanimUnavailable>());
      expect((result as ZmanimUnavailable).reason, ZmanimUnavailableReason.noLocationTimeZone);
      expect(repo.fetchCount, 0);
    });

    test('with no cache, fetches and returns the selected default 12', () async {
      repo.nextFetch = _snapshot();

      final result = await container.read(zmanimControllerProvider(query()).future);

      expect(result, isA<ZmanimAvailable>());
      expect((result as ZmanimAvailable).zmanim.map((z) => z.displayName), containsAll(['Netz', 'Shkia']));
      expect(repo.fetchCount, 1);
    });

    test('with a cache already present for today, returns it without a network fetch', () async {
      repo.cached = _snapshot();

      final result = await container.read(zmanimControllerProvider(query()).future);

      expect(result, isA<ZmanimAvailable>());
      expect(repo.fetchCount, 0);
    });

    test('with no cache and a failed fetch, becomes unavailable(temporaryError)', () async {
      repo.fetchError = const ZmanimServerException(500);

      final result = await container.read(zmanimControllerProvider(query()).future);

      expect(result, isA<ZmanimUnavailable>());
      expect((result as ZmanimUnavailable).reason, ZmanimUnavailableReason.temporaryError);
    });

    test('a Zmanim fetch failure does not throw out of the provider', () async {
      repo.fetchError = const ZmanimNetworkException();

      await expectLater(container.read(zmanimControllerProvider(query()).future), completes);
      final state = container.read(zmanimControllerProvider(query()));
      expect(state.hasError, isFalse);
    });
  });

  group('configuration reactivity', () {
    test('disabling a zman in settings updates the controller output without a new fetch', () async {
      repo.cached = _snapshot();
      await container.read(zmanimControllerProvider(query()).future);

      await container.read(zmanimConfigurationProvider.notifier).setEnabled('netz', false);
      // Re-reading the provider after its dependency (configuration)
      // changed reflects the new selection.
      final result = await container.read(zmanimControllerProvider(query()).future);

      expect((result as ZmanimAvailable).zmanim.map((z) => z.displayName), isNot(contains('Netz')));
      expect(repo.fetchCount, 0, reason: 'a pure display-config change should never hit the network');
    });
  });

  group('ensureFresh', () {
    test('is a no-op (no fetch) when today\'s cache is already present', () async {
      repo.cached = _snapshot();
      await container.read(zmanimControllerProvider(query()).future);
      expect(repo.fetchCount, 0);

      await container.read(zmanimControllerProvider(query()).notifier).ensureFresh();

      expect(repo.fetchCount, 0);
    });

    test('fetches when today\'s cache is missing (e.g. the calendar date rolled over)', () async {
      // No cache at all -- build() itself fetches once already; ensureFresh
      // should not fetch again while getCached still returns nothing new
      // to add, since the repo fake's `cached` stays null throughout.
      repo.nextFetch = _snapshot();
      await container.read(zmanimControllerProvider(query()).future);
      expect(repo.fetchCount, 1);

      await container.read(zmanimControllerProvider(query()).notifier).ensureFresh();

      expect(repo.fetchCount, 2);
    });

    test('a failed ensureFresh leaves the previous data on screen without an error state', () async {
      repo.nextFetch = _snapshot();
      await container.read(zmanimControllerProvider(query()).future);

      repo.fetchError = const ZmanimNetworkException();
      await container.read(zmanimControllerProvider(query()).notifier).ensureFresh();

      final state = container.read(zmanimControllerProvider(query()));
      expect(state.hasValue, isTrue);
      expect(state.value, isA<ZmanimAvailable>());
      expect(state.hasError, isFalse);
    });

    test('with a null time zone, is a no-op', () async {
      await container.read(zmanimControllerProvider(query(timeZone: null)).future);

      await container.read(zmanimControllerProvider(query(timeZone: null)).notifier).ensureFresh();

      expect(repo.fetchCount, 0);
    });
  });
}
