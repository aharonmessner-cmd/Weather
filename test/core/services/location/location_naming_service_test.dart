import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather/core/services/location/location_naming_service.dart';
import 'package:weather/core/services/nws/nws_api_client.dart';

import '../../../support/fixture.dart';

void main() {
  test('resolves "City, ST" from the point\'s relative-location metadata', () async {
    final client = NwsApiClient(
      httpClient: MockClient((_) async => http.Response(loadFixtureRaw('points.json'), 200)),
    );
    final service = LocationNamingService(client);

    final result = await service.resolve(latitude: 38.8894, longitude: -77.0352);

    expect(result, isA<LocationNamingResolved>());
    expect((result as LocationNamingResolved).cityState, 'Arlington, VA');
  });

  test('resolves with a null cityState (not a failure) when the point has no relative-location metadata', () async {
    final client = NwsApiClient(
      httpClient: MockClient((_) async => http.Response(
            '{"properties": {"gridId": "LWX", "gridX": 1, "gridY": 1, '
            '"forecast": "https://api.weather.gov/f", "forecastHourly": "https://api.weather.gov/fh", '
            '"observationStations": "https://api.weather.gov/os"}}',
            200,
          )),
    );
    final service = LocationNamingService(client);

    final result = await service.resolve(latitude: 0, longitude: 0);

    expect(result, isA<LocationNamingResolved>());
    expect((result as LocationNamingResolved).cityState, isNull);
  });

  test('a 404 from NWS (no coverage at this point) resolves as unavailable', () async {
    final client = NwsApiClient(
      httpClient: MockClient((_) async => http.Response('not found', 404)),
    );
    final service = LocationNamingService(client);

    final result = await service.resolve(latitude: 0, longitude: 0);

    expect(result, isA<LocationNamingUnavailable>());
  });

  test('a network/server failure resolves as a temporary failure, not unavailable', () async {
    final client = NwsApiClient(
      httpClient: MockClient((_) async => http.Response('error', 503)),
    );
    final service = LocationNamingService(client);

    final result = await service.resolve(latitude: 0, longitude: 0);

    expect(result, isA<LocationNamingFailed>());
  });

  test('an unparseable point resolves as a temporary failure', () async {
    final client = NwsApiClient(
      httpClient: MockClient((_) async => http.Response('{"properties": {}}', 200)),
    );
    final service = LocationNamingService(client);

    final result = await service.resolve(latitude: 0, longitude: 0);

    expect(result, isA<LocationNamingFailed>());
  });
}
