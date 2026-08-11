import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/models/geocode_result.dart';
import 'package:weather/core/services/geocoding/nominatim_geocoding_client.dart';
import 'package:weather/features/locations/application/location_search_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Builds a client wired to a canned JSON array response (or a fixed HTTP
/// status for error-path tests), so the controller's state-machine
/// transitions can be exercised without a real geocoding call.
NominatimGeocodingClient _clientReturning({String body = '[]', int status = 200}) {
  return NominatimGeocodingClient(httpClient: MockClient((_) async => http.Response(body, status)));
}

void main() {
  test('starts idle', () {
    final container = ProviderContainer(overrides: [geocodingClientProvider.overrideWithValue(_clientReturning())]);
    addTearDown(container.dispose);

    expect(container.read(locationSearchControllerProvider), isA<LocationSearchIdle>());
  });

  test('a blank query resets to idle without making a request', () async {
    final container = ProviderContainer(overrides: [geocodingClientProvider.overrideWithValue(_clientReturning())]);
    addTearDown(container.dispose);

    await container.read(locationSearchControllerProvider.notifier).search('   ');

    expect(container.read(locationSearchControllerProvider), isA<LocationSearchIdle>());
  });

  test('a successful search with results transitions to LocationSearchResults', () async {
    const body = '[{"lat": "38.8894", "lon": "-77.0352", "name": "Washington", '
        '"address": {"city": "Washington", "state": "District of Columbia", "country": "United States"}}]';
    final container = ProviderContainer(overrides: [
      geocodingClientProvider.overrideWithValue(_clientReturning(body: body)),
    ]);
    addTearDown(container.dispose);

    await container.read(locationSearchControllerProvider.notifier).search('Washington, DC');

    final state = container.read(locationSearchControllerProvider);
    expect(state, isA<LocationSearchResults>());
    final results = (state as LocationSearchResults).results;
    expect(results, hasLength(1));
    expect(results.single, isA<GeocodeResult>());
    expect(results.single.name, 'Washington');
  });

  test('a search with no results transitions to LocationSearchEmpty', () async {
    final container = ProviderContainer(overrides: [geocodingClientProvider.overrideWithValue(_clientReturning())]);
    addTearDown(container.dispose);

    await container.read(locationSearchControllerProvider.notifier).search('Nowhereville');

    expect(container.read(locationSearchControllerProvider), isA<LocationSearchEmpty>());
  });

  test('a malformed response transitions to LocationSearchError, not an uncaught exception', () async {
    final container = ProviderContainer(overrides: [
      geocodingClientProvider.overrideWithValue(_clientReturning(body: 'not json')),
    ]);
    addTearDown(container.dispose);

    await container.read(locationSearchControllerProvider.notifier).search('Anywhere');

    expect(container.read(locationSearchControllerProvider), isA<LocationSearchError>());
  });

  test('a network failure transitions to LocationSearchError', () async {
    final client = NominatimGeocodingClient(
      httpClient: MockClient((_) async => throw const SocketException('no network')),
    );
    final container = ProviderContainer(overrides: [geocodingClientProvider.overrideWithValue(client)]);
    addTearDown(container.dispose);

    await container.read(locationSearchControllerProvider.notifier).search('Anywhere');

    expect(container.read(locationSearchControllerProvider), isA<LocationSearchError>());
  });

  test('a rate-limit response transitions to LocationSearchError with a specific message', () async {
    final container = ProviderContainer(overrides: [
      geocodingClientProvider.overrideWithValue(_clientReturning(status: 429)),
    ]);
    addTearDown(container.dispose);

    await container.read(locationSearchControllerProvider.notifier).search('Anywhere');

    final state = container.read(locationSearchControllerProvider);
    expect(state, isA<LocationSearchError>());
    expect((state as LocationSearchError).message, contains('Too many'));
  });

  test('immediately after calling search, state is Loading (set synchronously before the request completes)', () async {
    final gate = Completer<http.Response>();
    final client = NominatimGeocodingClient(httpClient: MockClient((_) => gate.future));
    final container = ProviderContainer(overrides: [geocodingClientProvider.overrideWithValue(client)]);
    addTearDown(container.dispose);

    final future = container.read(locationSearchControllerProvider.notifier).search('Anywhere');
    expect(container.read(locationSearchControllerProvider), isA<LocationSearchLoading>());

    gate.complete(http.Response('[]', 200));
    await future;
    expect(container.read(locationSearchControllerProvider), isA<LocationSearchEmpty>());
  });

  test('a later search overwrites the previous results', () async {
    const body = '[{"lat": "1", "lon": "2", "name": "First", "address": {"city": "First", "country": "United States"}}]';
    final container = ProviderContainer(overrides: [
      geocodingClientProvider.overrideWithValue(_clientReturning(body: body)),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(locationSearchControllerProvider.notifier);

    await notifier.search('First');
    expect(container.read(locationSearchControllerProvider), isA<LocationSearchResults>());

    await notifier.search('');
    expect(container.read(locationSearchControllerProvider), isA<LocationSearchIdle>());
  });
}
