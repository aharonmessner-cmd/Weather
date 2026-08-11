import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/core/services/location/device_location_service.dart';

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool servicesEnabled = true;
  LocationPermission checkPermissionResult = LocationPermission.whileInUse;
  LocationPermission? requestPermissionResult;
  Object? getCurrentPositionError;
  Position? position;
  bool openAppSettingsCalled = false;
  bool openLocationSettingsCalled = false;

  @override
  Future<bool> isLocationServiceEnabled() async => servicesEnabled;

  @override
  Future<LocationPermission> checkPermission() async => checkPermissionResult;

  @override
  Future<LocationPermission> requestPermission() async => requestPermissionResult ?? checkPermissionResult;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    final error = getCurrentPositionError;
    if (error != null) {
      if (error is Exception) throw error;
      // ignore: only_throw_errors
      throw error;
    }
    return position!;
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalled = true;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalled = true;
    return true;
  }
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

void main() {
  late _FakeGeolocatorPlatform fake;
  late DeviceLocationService service;

  setUp(() {
    fake = _FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = fake;
    service = DeviceLocationService();
  });

  test('permission already granted returns the device coordinates', () async {
    fake.checkPermissionResult = LocationPermission.whileInUse;
    fake.position = _positionAt(lat: 40.0, lon: -74.0);

    final result = await service.getCurrentLocation();

    expect(result, isA<DeviceLocationSuccess>());
    final success = result as DeviceLocationSuccess;
    expect(success.latitude, 40.0);
    expect(success.longitude, -74.0);
  });

  test('permission initially undetermined is requested once, and granting it succeeds', () async {
    fake.checkPermissionResult = LocationPermission.denied;
    fake.requestPermissionResult = LocationPermission.whileInUse;
    fake.position = _positionAt();

    final result = await service.getCurrentLocation();

    expect(result, isA<DeviceLocationSuccess>());
  });

  test('permission denied (including after asking again) reports permissionDenied', () async {
    fake.checkPermissionResult = LocationPermission.denied;
    fake.requestPermissionResult = LocationPermission.denied;

    final result = await service.getCurrentLocation();

    expect(result, isA<DeviceLocationPermissionDenied>());
  });

  test('permission permanently denied reports permissionDeniedForever without re-prompting', () async {
    fake.checkPermissionResult = LocationPermission.deniedForever;

    final result = await service.getCurrentLocation();

    expect(result, isA<DeviceLocationPermissionDeniedForever>());
  });

  test('location services disabled is reported before even checking permission', () async {
    fake.servicesEnabled = false;

    final result = await service.getCurrentLocation();

    expect(result, isA<DeviceLocationServicesDisabled>());
  });

  test('a timeout while acquiring a fix reports timeout', () async {
    fake.getCurrentPositionError = TimeoutException('no fix');

    final result = await service.getCurrentLocation();

    expect(result, isA<DeviceLocationTimeout>());
  });

  test('services becoming disabled mid-request reports servicesDisabled', () async {
    fake.getCurrentPositionError = const LocationServiceDisabledException();

    final result = await service.getCurrentLocation();

    expect(result, isA<DeviceLocationServicesDisabled>());
  });

  test('permission revoked mid-request reports permissionDenied', () async {
    fake.getCurrentPositionError = const PermissionDeniedException('revoked');

    final result = await service.getCurrentLocation();

    expect(result, isA<DeviceLocationPermissionDenied>());
  });

  test('an unrecognized failure reports unavailable rather than throwing', () async {
    fake.getCurrentPositionError = const PositionUpdateException('platform error');

    final result = await service.getCurrentLocation();

    expect(result, isA<DeviceLocationUnavailable>());
  });

  test('openAppSettings and openLocationSettings delegate to the platform', () async {
    await service.openAppSettings();
    await service.openLocationSettings();

    expect(fake.openAppSettingsCalled, isTrue);
    expect(fake.openLocationSettingsCalled, isTrue);
  });
}
