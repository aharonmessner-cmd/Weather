import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/repositories/allergy_repository.dart';
import 'package:weather/core/services/allergy/allergy_client.dart';
import 'package:weather/core/services/allergy/allergy_exceptions.dart';
import 'package:weather/core/services/cache/allergy_cache.dart';

const _location = Location(id: 'home', name: 'Home', latitude: 38.8894, longitude: -77.0352);

DateTime _fixedNow() => DateTime.utc(2026, 8, 13, 12);

typedef _Router = Future<http.Response> Function(http.Request request);

AllergyClient _clientWith(_Router router) => AllergyClient(httpClient: MockClient(router));

Future<http.Response> _happyPathRouter(http.Request request) async {
  return http.Response('{"current": {"dust": 8.5}}', 200);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AllergyCache> newCache() async {
    SharedPreferences.setMockInitialValues({});
    return AllergyCache(await SharedPreferences.getInstance());
  }

  group('OpenMeteoAllergyRepository.fetchAndCache', () {
    test('parses the response into AllergyData and caches it', () async {
      final cache = await newCache();
      final repo = OpenMeteoAllergyRepository(client: _clientWith(_happyPathRouter), cache: cache, now: _fixedNow);

      final data = await repo.fetchAndCache(_location);

      expect(data.location, _location);
      expect(data.generatedAt, _fixedNow());
      expect(data.dustMicrogramsPerCubicMeter, 8.5);

      final cached = await cache.read(_location.id);
      expect(cached, isNotNull);
      expect(cached!.location, _location);
    });

    test('propagates an AllergyException instead of caching anything', () async {
      final cache = await newCache();
      final repo = OpenMeteoAllergyRepository(
        client: _clientWith((_) async => http.Response('boom', 503)),
        cache: cache,
        now: _fixedNow,
      );

      await expectLater(repo.fetchAndCache(_location), throwsA(isA<AllergyServerException>()));
      expect(await cache.read(_location.id), isNull);
    });
  });

  group('OpenMeteoAllergyRepository.getCached', () {
    test('returns null before anything has been fetched', () async {
      final cache = await newCache();
      final repo = OpenMeteoAllergyRepository(client: _clientWith(_happyPathRouter), cache: cache, now: _fixedNow);

      expect(await repo.getCached(_location), isNull);
    });

    test('returns the last cached snapshot after a successful fetch', () async {
      final cache = await newCache();
      final repo = OpenMeteoAllergyRepository(client: _clientWith(_happyPathRouter), cache: cache, now: _fixedNow);

      final fetched = await repo.fetchAndCache(_location);
      final cachedAfter = await repo.getCached(_location);

      expect(cachedAfter, fetched);
    });
  });
}
