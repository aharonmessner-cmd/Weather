import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/repositories/weather_repository.dart';
import 'package:weather/core/services/cache/weather_cache.dart';
import 'package:weather/core/services/nws/nws_api_client.dart';
import 'package:weather/core/services/nws/nws_exceptions.dart';

import '../../support/fixture.dart';

const _location = Location(id: 'home', name: 'Home', latitude: 38.8894, longitude: -77.0352);

typedef _Router = Future<http.Response> Function(http.Request request);

http.Client _clientWith(_Router router) => MockClient(router);

Future<http.Response> _happyPathRouter(http.Request request) async {
  final path = request.url.path;
  if (path.startsWith('/points/')) {
    return http.Response(loadFixtureRaw('points.json'), 200);
  }
  if (path.contains('/forecast/hourly')) {
    return http.Response(loadFixtureRaw('forecast_hourly.json'), 200);
  }
  if (path.contains('/forecast')) {
    return http.Response(loadFixtureRaw('forecast.json'), 200);
  }
  if (path.contains('/stations') && !path.contains('/observations')) {
    return http.Response(loadFixtureRaw('stations.json'), 200);
  }
  if (path.contains('/observations/latest')) {
    return http.Response(loadFixtureRaw('observation_latest.json'), 200);
  }
  if (path.startsWith('/alerts/active')) {
    return http.Response(loadFixtureRaw('alerts_active.json'), 200);
  }
  return http.Response('not found', 404);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<WeatherCache> newCache() async {
    SharedPreferences.setMockInitialValues({});
    return WeatherCache(await SharedPreferences.getInstance());
  }

  group('NwsWeatherRepository.fetchAndCache', () {
    test('assembles a full WeatherData from all endpoints and caches it', () async {
      final cache = await newCache();
      final repo = NwsWeatherRepository(
        client: NwsApiClient(httpClient: _clientWith(_happyPathRouter)),
        cache: cache,
      );

      final data = await repo.fetchAndCache(_location);

      expect(data.location, _location);
      expect(data.current.temperatureFahrenheit, isNotNull);
      expect(data.observation, isNotNull);
      expect(data.observation!.stationId, 'KDCA');
      expect(data.hourly, isNotEmpty);
      expect(data.daily, isNotEmpty);
      expect(data.alerts, hasLength(1));
      expect(data.alerts.single.event, 'Heat Advisory');

      final cached = await cache.read(_location.id);
      expect(cached, isNotNull);
      expect(cached!.location, _location);
    });

    test('propagates a not-found error from point resolution', () async {
      final cache = await newCache();
      final repo = NwsWeatherRepository(
        client: NwsApiClient(httpClient: _clientWith((_) async => http.Response('nope', 404))),
        cache: cache,
      );

      await expectLater(repo.fetchAndCache(_location), throwsA(isA<NwsNotFoundException>()));
      expect(await cache.read(_location.id), isNull);
    });

    test('propagates a server error from the forecast endpoint', () async {
      final cache = await newCache();
      final _Router router = (request) async {
        if (request.url.path.startsWith('/points/')) {
          return http.Response(loadFixtureRaw('points.json'), 200);
        }
        return http.Response('boom', 503);
      };
      final repo = NwsWeatherRepository(
        client: NwsApiClient(httpClient: _clientWith(router)),
        cache: cache,
      );

      await expectLater(repo.fetchAndCache(_location), throwsA(isA<NwsServerException>()));
    });

    test('still succeeds when the observation station lookup fails entirely', () async {
      final cache = await newCache();
      final _Router router = (request) async {
        final path = request.url.path;
        if (path.contains('/stations') && !path.contains('/observations')) {
          return http.Response('unavailable', 503);
        }
        return _happyPathRouter(request);
      };
      final repo = NwsWeatherRepository(
        client: NwsApiClient(httpClient: _clientWith(router)),
        cache: cache,
      );

      final data = await repo.fetchAndCache(_location);
      expect(data.observation, isNull);
      // Current conditions should still fall back to the forecast period.
      expect(data.current.temperatureFahrenheit, isNotNull);
    });

    test('falls back to the next-nearest station when the closest one has no data', () async {
      final cache = await newCache();
      final _Router router = (request) async {
        final path = request.url.path;
        if (path.contains('/observations/latest')) {
          if (path.contains('KDCA')) return http.Response('offline', 503);
          return http.Response(loadFixtureRaw('observation_latest.json'), 200);
        }
        return _happyPathRouter(request);
      };
      final repo = NwsWeatherRepository(
        client: NwsApiClient(httpClient: _clientWith(router)),
        cache: cache,
      );

      final data = await repo.fetchAndCache(_location);
      expect(data.observation, isNotNull);
      expect(data.observation!.stationId, 'KADW');
    });

    test('still succeeds when the alerts endpoint fails', () async {
      final cache = await newCache();
      final _Router router = (request) async {
        if (request.url.path.startsWith('/alerts/active')) {
          return http.Response('boom', 500);
        }
        return _happyPathRouter(request);
      };
      final repo = NwsWeatherRepository(
        client: NwsApiClient(httpClient: _clientWith(router)),
        cache: cache,
      );

      final data = await repo.fetchAndCache(_location);
      expect(data.alerts, isEmpty);
    });

    test('throws a parse exception when the forecast response has no periods', () async {
      final cache = await newCache();
      final _Router router = (request) async {
        if (request.url.path.contains('/forecast') && !request.url.path.contains('hourly')) {
          return http.Response('{"properties": {}}', 200);
        }
        return _happyPathRouter(request);
      };
      final repo = NwsWeatherRepository(
        client: NwsApiClient(httpClient: _clientWith(router)),
        cache: cache,
      );

      await expectLater(repo.fetchAndCache(_location), throwsA(isA<NwsParseException>()));
    });
  });

  group('NwsWeatherRepository.getCached', () {
    test('returns null before anything has been fetched', () async {
      final cache = await newCache();
      final repo = NwsWeatherRepository(
        client: NwsApiClient(httpClient: _clientWith(_happyPathRouter)),
        cache: cache,
      );

      expect(await repo.getCached(_location), isNull);
    });
  });
}
