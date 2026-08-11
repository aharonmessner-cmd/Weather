import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/models/current_conditions.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/models/weather_data.dart';
import 'package:weather/core/repositories/weather_repository.dart';
import 'package:weather/core/services/geocoding/nominatim_geocoding_client.dart';
import 'package:weather/core/services/location/device_location_service.dart';
import 'package:weather/core/services/nws/nws_api_client.dart';
import 'package:weather/features/locations/application/current_location_controller.dart';
import 'package:weather/features/locations/application/location_search_controller.dart';
import 'package:weather/features/locations/application/locations_controller.dart';
import 'package:weather/features/weather/application/weather_controller.dart';

import '../../support/fixture.dart';

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    return Position(
      latitude: 38.8894,
      longitude: -77.0352,
      timestamp: DateTime.utc(2026, 8, 11),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

/// Proves the weather pipeline treats every [Location] identically
/// regardless of where it came from — it only ever needs `getCached`/
/// `fetchAndCache` to be called, never anything source-specific.
class _FakeWeatherRepository implements WeatherRepository {
  final calls = <Location>[];

  @override
  Future<WeatherData?> getCached(Location location) async => null;

  @override
  Future<WeatherData> fetchAndCache(Location location) async {
    calls.add(location);
    return WeatherData(
      location: location,
      current: const CurrentConditions(temperatureFahrenheit: 72),
      fetchedAt: DateTime.utc(2026, 8, 11),
    );
  }
}

void main() {
  test(
    'Use My Location, Search, and Advanced Coordinates all produce ordinary Locations that flow through the same weather pipeline',
    () async {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform();

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final nwsClient = NwsApiClient(
        httpClient: MockClient((_) async => http.Response(loadFixtureRaw('points.json'), 200)),
      );
      const geocodeSearchBody = '[{"lat": "44.2", "lon": "-71.5", "name": "Camp Runamuck", '
          '"address": {"village": "Camp Runamuck", "state": "New Hampshire", "country": "United States"}}]';
      final geocodingClient = NominatimGeocodingClient(
        httpClient: MockClient((_) async => http.Response(geocodeSearchBody, 200)),
      );
      final weatherRepository = _FakeWeatherRepository();

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nwsApiClientProvider.overrideWithValue(nwsClient),
        deviceLocationServiceProvider.overrideWithValue(DeviceLocationService()),
        geocodingClientProvider.overrideWithValue(geocodingClient),
        weatherRepositoryProvider.overrideWithValue(weatherRepository),
      ]);
      addTearDown(container.dispose);

      // Path 1: Use My Location.
      await container.read(currentLocationControllerProvider.notifier).useMyLocation();
      final deviceState = container.read(currentLocationControllerProvider) as CurrentLocationSucceeded;
      final deviceLocation = deviceState.location;

      // Path 2: Search — mirrors exactly what LocationSearchSheet._select
      // does: add() the chosen GeocodeResult's fields, then select it.
      await container.read(locationSearchControllerProvider.notifier).search('Camp Runamuck');
      final searchState = container.read(locationSearchControllerProvider) as LocationSearchResults;
      final geocodeResult = searchState.results.single;
      final searchSave = await container.read(locationsControllerProvider.notifier).add(
            name: geocodeResult.name,
            latitude: geocodeResult.latitude,
            longitude: geocodeResult.longitude,
            address: geocodeResult.subtitle,
          );
      container.read(selectedLocationIdProvider.notifier).state = searchSave.location.id;
      final searchLocation = searchSave.location;

      // Path 3: Advanced coordinates — mirrors LocationEditorSheet._save's
      // non-editing branch.
      final advancedSave = await container.read(locationsControllerProvider.notifier).add(
            name: 'Cabin',
            latitude: 43.2,
            longitude: -72.1,
          );
      final advancedLocation = advancedSave.location;

      // All three are ordinary, independently-addressable Locations.
      final saved = container.read(locationsControllerProvider);
      expect(saved, containsAll([deviceLocation, searchLocation, advancedLocation]));
      expect(saved.map((l) => l.id).toSet(), hasLength(3));

      // Every one of them drives weather through the exact same repository
      // calls — nothing source-specific in the weather pipeline.
      for (final location in [deviceLocation, searchLocation, advancedLocation]) {
        final data = await container.read(weatherControllerProvider(location).future);
        expect(data.location, location);
        expect(data.current.temperatureFahrenheit, 72);
      }
      expect(weatherRepository.calls, containsAll([deviceLocation, searchLocation, advancedLocation]));
    },
  );
}
