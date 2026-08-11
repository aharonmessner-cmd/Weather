import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/services/location/device_location_service.dart';
import 'package:weather/core/services/nws/nws_api_client.dart';
import 'package:weather/features/locations/application/current_location_controller.dart';
import 'package:weather/features/locations/application/locations_controller.dart';

import '../../../support/fixture.dart';

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool servicesEnabled = true;
  LocationPermission checkPermissionResult = LocationPermission.whileInUse;
  LocationPermission? requestPermissionResult;
  Position? position;
  Object? getCurrentPositionError;

  @override
  Future<bool> isLocationServiceEnabled() async => servicesEnabled;

  @override
  Future<LocationPermission> checkPermission() async => checkPermissionResult;

  @override
  Future<LocationPermission> requestPermission() async => requestPermissionResult ?? checkPermissionResult;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    final error = getCurrentPositionError;
    if (error != null) throw error;
    return position!;
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

Position _positionAt({double lat = 38.8894, double lon = -77.0352}) {
  return Position(
    latitude: lat,
    longitude: lon,
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

Future<ProviderContainer> _container({
  required _FakeGeolocatorPlatform geolocator,
  int pointsStatus = 200,
  String? pointsBody,
}) async {
  GeolocatorPlatform.instance = geolocator;

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final nwsClient = NwsApiClient(
    httpClient: MockClient((_) async => http.Response(pointsBody ?? loadFixtureRaw('points.json'), pointsStatus)),
  );

  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    nwsApiClientProvider.overrideWithValue(nwsClient),
    deviceLocationServiceProvider.overrideWithValue(DeviceLocationService()),
  ]);
}

void main() {
  test('the full success path: device coordinates -> NWS point -> saved and selected Location', () async {
    final geolocator = _FakeGeolocatorPlatform()..position = _positionAt();
    final container = await _container(geolocator: geolocator);
    addTearDown(container.dispose);

    await container.read(currentLocationControllerProvider.notifier).useMyLocation();

    final state = container.read(currentLocationControllerProvider);
    expect(state, isA<CurrentLocationSucceeded>());
    final succeeded = state as CurrentLocationSucceeded;
    expect(succeeded.wasDuplicate, isFalse);
    // points.json's relativeLocation is Arlington, VA.
    expect(succeeded.location.name, 'Arlington, VA');
    expect(succeeded.location.latitude, 38.8894);
    expect(succeeded.location.longitude, -77.0352);

    expect(container.read(locationsControllerProvider), contains(succeeded.location));
    expect(container.read(selectedLocationIdProvider), succeeded.location.id);
  });

  test('permission denied', () async {
    final geolocator = _FakeGeolocatorPlatform()
      ..checkPermissionResult = LocationPermission.denied
      ..requestPermissionResult = LocationPermission.denied;
    final container = await _container(geolocator: geolocator);
    addTearDown(container.dispose);

    await container.read(currentLocationControllerProvider.notifier).useMyLocation();

    final state = container.read(currentLocationControllerProvider);
    expect(state, isA<CurrentLocationFailed>());
    expect((state as CurrentLocationFailed).reason, CurrentLocationFailureReason.permissionDenied);
    expect(container.read(locationsControllerProvider), isEmpty);
  });

  test('permission denied permanently', () async {
    final geolocator = _FakeGeolocatorPlatform()..checkPermissionResult = LocationPermission.deniedForever;
    final container = await _container(geolocator: geolocator);
    addTearDown(container.dispose);

    await container.read(currentLocationControllerProvider.notifier).useMyLocation();

    final state = container.read(currentLocationControllerProvider) as CurrentLocationFailed;
    expect(state.reason, CurrentLocationFailureReason.permissionDeniedForever);
  });

  test('location services disabled', () async {
    final geolocator = _FakeGeolocatorPlatform()..servicesEnabled = false;
    final container = await _container(geolocator: geolocator);
    addTearDown(container.dispose);

    await container.read(currentLocationControllerProvider.notifier).useMyLocation();

    final state = container.read(currentLocationControllerProvider) as CurrentLocationFailed;
    expect(state.reason, CurrentLocationFailureReason.servicesDisabled);
  });

  test('timeout acquiring a fix', () async {
    final geolocator = _FakeGeolocatorPlatform()..getCurrentPositionError = TimeoutException('no fix');
    final container = await _container(geolocator: geolocator);
    addTearDown(container.dispose);

    await container.read(currentLocationControllerProvider.notifier).useMyLocation();

    final state = container.read(currentLocationControllerProvider) as CurrentLocationFailed;
    expect(state.reason, CurrentLocationFailureReason.timeout);
  });

  test('device location unavailable (unrecognized platform failure)', () async {
    final geolocator = _FakeGeolocatorPlatform()..getCurrentPositionError = const PositionUpdateException('platform error');
    final container = await _container(geolocator: geolocator);
    addTearDown(container.dispose);

    await container.read(currentLocationControllerProvider.notifier).useMyLocation();

    final state = container.read(currentLocationControllerProvider) as CurrentLocationFailed;
    expect(state.reason, CurrentLocationFailureReason.unavailable);
  });

  test('NWS has no coverage at this point (outside NWS territory)', () async {
    final geolocator = _FakeGeolocatorPlatform()..position = _positionAt(lat: 0, lon: 0);
    final container = await _container(geolocator: geolocator, pointsStatus: 404, pointsBody: 'not found');
    addTearDown(container.dispose);

    await container.read(currentLocationControllerProvider.notifier).useMyLocation();

    final state = container.read(currentLocationControllerProvider) as CurrentLocationFailed;
    expect(state.reason, CurrentLocationFailureReason.nwsUnavailable);
    expect(container.read(locationsControllerProvider), isEmpty);
  });

  test('a temporary NWS failure while naming does not save a location', () async {
    final geolocator = _FakeGeolocatorPlatform()..position = _positionAt();
    final container = await _container(geolocator: geolocator, pointsStatus: 503, pointsBody: 'error');
    addTearDown(container.dispose);

    await container.read(currentLocationControllerProvider.notifier).useMyLocation();

    final state = container.read(currentLocationControllerProvider) as CurrentLocationFailed;
    expect(state.reason, CurrentLocationFailureReason.nwsTemporaryError);
    expect(container.read(locationsControllerProvider), isEmpty);
  });

  test('a duplicate coordinate selects the existing location instead of creating a new one', () async {
    final geolocator = _FakeGeolocatorPlatform()..position = _positionAt();
    final container = await _container(geolocator: geolocator);
    addTearDown(container.dispose);
    final existing = await container.read(locationsControllerProvider.notifier).add(
          name: 'Home',
          latitude: 38.8894,
          longitude: -77.0352,
        );

    await container.read(currentLocationControllerProvider.notifier).useMyLocation();

    final state = container.read(currentLocationControllerProvider) as CurrentLocationSucceeded;
    expect(state.wasDuplicate, isTrue);
    expect(state.location.id, existing.location.id);
    expect(container.read(locationsControllerProvider), hasLength(1));
    expect(container.read(selectedLocationIdProvider), existing.location.id);
  });
}
