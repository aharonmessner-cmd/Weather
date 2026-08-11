import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather/core/services/geocoding/geocoding_exceptions.dart';
import 'package:weather/core/services/geocoding/nominatim_geocoding_client.dart';

Map<String, dynamic> _place({
  required String lat,
  required String lon,
  required String name,
  String? county,
  String? state,
  String country = 'United States',
  String cityField = 'town',
}) {
  return {
    'lat': lat,
    'lon': lon,
    'name': name,
    'display_name': '$name, ${county ?? ''}, $state, $country',
    'address': {
      cityField: name,
      if (county != null) 'county': county,
      if (state != null) 'state': state,
      'country': country,
    },
  };
}

void main() {
  test('a successful search returns clean name/subtitle results, not the raw display_name', () async {
    final client = NominatimGeocodingClient(
      httpClient: MockClient((_) async => http.Response(
            '[${_placeJson(_place(lat: '38.8894', lon: '-77.0352', name: 'Washington', state: 'District of Columbia'))}]',
            200,
          )),
    );

    final results = await client.search('Washington, DC');

    expect(results, hasLength(1));
    expect(results.single.name, 'Washington');
    expect(results.single.subtitle, 'District of Columbia, United States');
    expect(results.single.latitude, 38.8894);
    expect(results.single.longitude, -77.0352);
  });

  test('same-named results in different states are disambiguated with county instead of a repeated subtitle', () async {
    final ny = _place(lat: '41.4459', lon: '-74.4229', name: 'Middletown', county: 'Orange County', state: 'New York');
    final nj = _place(lat: '40.3737', lon: '-74.1141', name: 'Middletown', county: 'Monmouth County', state: 'New Jersey');
    final client = NominatimGeocodingClient(
      httpClient: MockClient((_) async => http.Response('[${_placeJson(ny)}, ${_placeJson(nj)}]', 200)),
    );

    final results = await client.search('Middletown');

    expect(results, hasLength(2));
    expect(results[0].name, 'Middletown');
    expect(results[0].subtitle, 'Orange County, New York');
    expect(results[1].name, 'Middletown');
    expect(results[1].subtitle, 'Monmouth County, New Jersey');
  });

  test('the same name repeated anywhere in the results is disambiguated with county, even across different states', () async {
    final ny = _place(lat: '41.0', lon: '-74.0', name: 'Springfield', county: 'Ulster County', state: 'New York');
    final il = _place(lat: '39.0', lon: '-89.0', name: 'Springfield', county: 'Sangamon County', state: 'Illinois');
    final client = NominatimGeocodingClient(
      httpClient: MockClient((_) async => http.Response('[${_placeJson(ny)}, ${_placeJson(il)}]', 200)),
    );

    final results = await client.search('Springfield');

    expect(results.map((r) => r.subtitle), ['Ulster County, New York', 'Sangamon County, Illinois']);
  });

  test('a unique name uses the terse "State, Country" subtitle, not county', () async {
    final client = NominatimGeocodingClient(
      httpClient: MockClient((_) async => http.Response(
            '[${_placeJson(_place(lat: '41.0', lon: '-74.0', name: 'Middletown', county: 'Orange County', state: 'New York'))}]',
            200,
          )),
    );

    final results = await client.search('Middletown');

    expect(results.single.subtitle, 'New York, United States');
  });

  test('no results returns an empty list, not an error', () async {
    final client = NominatimGeocodingClient(httpClient: MockClient((_) async => http.Response('[]', 200)));

    final results = await client.search('Nowhereville');

    expect(results, isEmpty);
  });

  test('entries missing usable name or coordinates are skipped rather than failing the whole search', () async {
    final good = _place(lat: '38.0', lon: '-77.0', name: 'Goodtown', state: 'Virginia');
    const badNoName = '{"lat": "1", "lon": "2", "address": {"country": "United States"}}';
    const badNoCoords = '{"name": "Bad", "address": {"city": "Bad", "country": "United States"}}';
    final client = NominatimGeocodingClient(
      httpClient: MockClient((_) async => http.Response('[$badNoName, $badNoCoords, ${_placeJson(good)}]', 200)),
    );

    final results = await client.search('Goodtown');

    expect(results, hasLength(1));
    expect(results.single.name, 'Goodtown');
  });

  test('a non-list JSON body throws GeocodingParseException', () async {
    final client = NominatimGeocodingClient(httpClient: MockClient((_) async => http.Response('{"error": "bad"}', 200)));

    expect(client.search('x'), throwsA(isA<GeocodingParseException>()));
  });

  test('invalid JSON throws GeocodingParseException', () async {
    final client = NominatimGeocodingClient(httpClient: MockClient((_) async => http.Response('not json', 200)));

    expect(client.search('x'), throwsA(isA<GeocodingParseException>()));
  });

  test('a 429 response throws GeocodingRateLimitException', () async {
    final client = NominatimGeocodingClient(httpClient: MockClient((_) async => http.Response('rate limited', 429)));

    expect(client.search('x'), throwsA(isA<GeocodingRateLimitException>()));
  });

  test('a 5xx response throws GeocodingServerException', () async {
    final client = NominatimGeocodingClient(httpClient: MockClient((_) async => http.Response('error', 503)));

    expect(client.search('x'), throwsA(isA<GeocodingServerException>()));
  });

  test('a network failure throws GeocodingNetworkException', () async {
    final client = NominatimGeocodingClient(
      httpClient: MockClient((_) async => throw const SocketException('no network')),
    );

    expect(client.search('x'), throwsA(isA<GeocodingNetworkException>()));
  });

  test('every request carries a descriptive User-Agent per Nominatim\'s usage policy', () async {
    http.Request? captured;
    final client = NominatimGeocodingClient(
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response('[]', 200);
      }),
    );

    await client.search('Anywhere');

    expect(captured, isNotNull);
    expect(captured!.headers['User-Agent'], isNotNull);
    expect(captured!.headers['User-Agent'], isNotEmpty);
  });

  test('the search is restricted to US results', () async {
    http.Request? captured;
    final client = NominatimGeocodingClient(
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response('[]', 200);
      }),
    );

    await client.search('Paris');

    expect(captured!.url.queryParameters['countrycodes'], 'us');
  });
}

String _placeJson(Map<String, dynamic> place) {
  final address = place['address'] as Map<String, dynamic>;
  final addressJson = address.entries.map((e) => '"${e.key}": "${e.value}"').join(', ');
  return '{"lat": "${place['lat']}", "lon": "${place['lon']}", "name": "${place['name']}", '
      '"display_name": "${place['display_name']}", "address": {$addressJson}}';
}
