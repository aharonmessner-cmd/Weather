import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:weather/core/models/location.dart';
import 'package:weather/core/repositories/zmanim_repository.dart';
import 'package:weather/core/services/cache/zmanim_cache.dart';
import 'package:weather/core/services/zmanim/zmanim_client.dart';
import 'package:weather/core/services/zmanim/zmanim_exceptions.dart';

const _location = Location(id: 'home', name: 'Home', latitude: 38.8894, longitude: -77.0352);
const _tz = 'America/New_York';

DateTime _fixedNow() => DateTime.parse('2026-08-11T10:00:00-04:00');

typedef _Router = Future<http.Response> Function(http.Request request);

ZmanimClient _clientWith(_Router router) => ZmanimClient(httpClient: MockClient(router));

Future<http.Response> _happyPathRouter(http.Request request) async {
  expect(request.url.queryParameters['date'], '2026-08-11');
  return http.Response(
    '{"times": {"sunrise": "2026-08-11T06:08:00-04:00", "sunset": "2026-08-11T19:58:00-04:00"}}',
    200,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tzdata.initializeTimeZones);

  Future<ZmanimCache> newCache() async {
    SharedPreferences.setMockInitialValues({});
    return ZmanimCache(await SharedPreferences.getInstance());
  }

  group('HebcalZmanimRepository.fetchAndCache', () {
    test('requests today\'s location-local date and caches the result', () async {
      final cache = await newCache();
      final repo = HebcalZmanimRepository(client: _clientWith(_happyPathRouter), cache: cache, now: _fixedNow);

      final data = await repo.fetchAndCache(_location, _tz);

      expect(data.locationDate, '2026-08-11');
      expect(data.location, _location);
      expect(data.times, hasLength(2));

      final cached = await cache.read(_location.id, '2026-08-11');
      expect(cached, data);
    });

    test('propagates a ZmanimException instead of caching anything', () async {
      final cache = await newCache();
      final repo = HebcalZmanimRepository(
        client: _clientWith((_) async => http.Response('boom', 503)),
        cache: cache,
        now: _fixedNow,
      );

      await expectLater(repo.fetchAndCache(_location, _tz), throwsA(isA<ZmanimServerException>()));
      expect(await cache.read(_location.id, '2026-08-11'), isNull);
    });

    test('computes the location-local date, not the UTC date, just after UTC midnight', () async {
      // 2026-08-12 02:00 UTC is still 2026-08-11 22:00 in New York
      // (EDT, UTC-4) -- the UTC calendar date has already rolled over to
      // the 12th, but the location's has not. The request/cache date
      // must reflect the location, proving real tz-database conversion
      // is happening rather than a same-day coincidence.
      final cache = await newCache();
      final router = (http.Request request) async {
        expect(request.url.queryParameters['date'], '2026-08-11');
        return http.Response('{"times": {"sunrise": "2026-08-11T06:08:00-04:00"}}', 200);
      };
      final repo = HebcalZmanimRepository(
        client: _clientWith(router),
        cache: cache,
        now: () => DateTime.parse('2026-08-12T02:00:00Z'),
      );

      final data = await repo.fetchAndCache(_location, _tz);

      expect(data.locationDate, '2026-08-11');
    });

    test('computes the location-local date, not the UTC date, just before UTC midnight', () async {
      // 2026-08-11 23:00 UTC is already 2026-08-12 03:00 in Asia/Tokyo
      // (UTC+9) -- the opposite boundary direction from the New York
      // case above, for a location ahead of UTC instead of behind it.
      final cache = await newCache();
      final tokyo = const Location(id: 'tokyo', name: 'Tokyo', latitude: 35.6762, longitude: 139.6503);
      final router = (http.Request request) async {
        expect(request.url.queryParameters['date'], '2026-08-12');
        return http.Response('{"times": {"sunrise": "2026-08-12T04:50:00+09:00"}}', 200);
      };
      final repo = HebcalZmanimRepository(
        client: _clientWith(router),
        cache: cache,
        now: () => DateTime.parse('2026-08-11T23:00:00Z'),
      );

      final data = await repo.fetchAndCache(tokyo, 'Asia/Tokyo');

      expect(data.locationDate, '2026-08-12');
    });
  });

  group('HebcalZmanimRepository.getCached', () {
    test('returns null before anything has been fetched for today', () async {
      final cache = await newCache();
      final repo = HebcalZmanimRepository(client: _clientWith(_happyPathRouter), cache: cache, now: _fixedNow);

      expect(await repo.getCached(_location, _tz), isNull);
    });

    test('returns null for a cache entry from a different day (does not leak yesterday\'s data)', () async {
      final cache = await newCache();
      final repo = HebcalZmanimRepository(client: _clientWith(_happyPathRouter), cache: cache, now: _fixedNow);
      await repo.fetchAndCache(_location, _tz); // caches under 2026-08-11

      final tomorrow = () => DateTime.parse('2026-08-12T10:00:00-04:00');
      final repoTomorrow = HebcalZmanimRepository(client: _clientWith(_happyPathRouter), cache: cache, now: tomorrow);

      expect(await repoTomorrow.getCached(_location, _tz), isNull);
    });

    test('returns the cached snapshot after a successful fetch, for the same day', () async {
      final cache = await newCache();
      final repo = HebcalZmanimRepository(client: _clientWith(_happyPathRouter), cache: cache, now: _fixedNow);

      final fetched = await repo.fetchAndCache(_location, _tz);
      final cachedAfter = await repo.getCached(_location, _tz);

      expect(cachedAfter, fetched);
    });
  });
}
