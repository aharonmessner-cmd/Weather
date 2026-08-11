import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/repositories/minutecast_repository.dart';
import 'package:weather/core/services/cache/minutecast_cache.dart';
import 'package:weather/core/services/minutecast/minutecast_client.dart';
import 'package:weather/core/services/minutecast/minutecast_exceptions.dart';

const _location = Location(id: 'home', name: 'Home', latitude: 38.8894, longitude: -77.0352);

DateTime _fixedNow() => DateTime.utc(2026, 8, 11, 12);

typedef _Router = Future<http.Response> Function(http.Request request);

MinuteCastClient _clientWith(_Router router) {
  return MinuteCastClient(apiKey: 'test-key', httpClient: MockClient(router));
}

Future<http.Response> _happyPathRouter(http.Request request) async {
  return http.Response(
    '{"minutely": {"data": [{"time": 1755000000, "precipIntensity": 1.2, "precipType": "rain"}]}}',
    200,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<MinuteCastCache> newCache() async {
    SharedPreferences.setMockInitialValues({});
    return MinuteCastCache(await SharedPreferences.getInstance());
  }

  group('PirateWeatherMinuteCastRepository.fetchAndCache', () {
    test('parses the response into a MinuteCast and caches it', () async {
      final cache = await newCache();
      final repo = PirateWeatherMinuteCastRepository(
        client: _clientWith(_happyPathRouter),
        cache: cache,
        now: _fixedNow,
      );

      final data = await repo.fetchAndCache(_location);

      expect(data.location, _location);
      expect(data.generatedAt, _fixedNow());
      expect(data.minutes, hasLength(1));
      expect(data.minutes.single.type.name, 'rain');

      final cached = await cache.read(_location.id);
      expect(cached, isNotNull);
      expect(cached!.location, _location);
    });

    test('propagates a MinuteCastException instead of caching anything', () async {
      final cache = await newCache();
      final repo = PirateWeatherMinuteCastRepository(
        client: _clientWith((_) async => http.Response('boom', 503)),
        cache: cache,
        now: _fixedNow,
      );

      await expectLater(repo.fetchAndCache(_location), throwsA(isA<MinuteCastServerException>()));
      expect(await cache.read(_location.id), isNull);
    });

    test('propagates a not-configured error without caching', () async {
      final cache = await newCache();
      final repo = PirateWeatherMinuteCastRepository(
        client: MinuteCastClient(apiKey: '', httpClient: MockClient((_) async => http.Response('{}', 200))),
        cache: cache,
        now: _fixedNow,
      );

      await expectLater(repo.fetchAndCache(_location), throwsA(isA<MinuteCastNotConfiguredException>()));
      expect(await cache.read(_location.id), isNull);
    });
  });

  group('PirateWeatherMinuteCastRepository.getCached', () {
    test('returns null before anything has been fetched', () async {
      final cache = await newCache();
      final repo = PirateWeatherMinuteCastRepository(
        client: _clientWith(_happyPathRouter),
        cache: cache,
        now: _fixedNow,
      );

      expect(await repo.getCached(_location), isNull);
    });

    test('returns the last cached snapshot after a successful fetch', () async {
      final cache = await newCache();
      final repo = PirateWeatherMinuteCastRepository(
        client: _clientWith(_happyPathRouter),
        cache: cache,
        now: _fixedNow,
      );

      final fetched = await repo.fetchAndCache(_location);
      final cachedAfter = await repo.getCached(_location);

      expect(cachedAfter, fetched);
    });
  });
}
