import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Every outcome [DeviceLocationService.getCurrentLocation] can produce.
/// A sealed result type rather than throwing: each of these is an expected,
/// specifically-handled branch in the "Use My Location" UI (see the class
/// doc), not an exceptional failure.
sealed class DeviceLocationResult {
  const DeviceLocationResult();
}

class DeviceLocationSuccess extends DeviceLocationResult {
  const DeviceLocationSuccess({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// The user (or a prior app session) denied the permission request. Asking
/// again via [DeviceLocationService.getCurrentLocation] is fine — the OS
/// will show the prompt again.
class DeviceLocationPermissionDenied extends DeviceLocationResult {
  const DeviceLocationPermissionDenied();
}

/// The permission was denied permanently ("don't ask again" on Android, or
/// a prior explicit denial on iOS) — the OS will not show the prompt again.
/// The only way forward is [DeviceLocationService.openAppSettings].
class DeviceLocationPermissionDeniedForever extends DeviceLocationResult {
  const DeviceLocationPermissionDeniedForever();
}

/// Location permission is granted, but the device's location services
/// (GPS/location toggle) are off entirely. Recoverable via
/// [DeviceLocationService.openLocationSettings].
class DeviceLocationServicesDisabled extends DeviceLocationResult {
  const DeviceLocationServicesDisabled();
}

/// No fix was obtained within the configured time limit — a transient
/// condition (weak signal, indoors, cold GPS start) worth a plain retry.
class DeviceLocationTimeout extends DeviceLocationResult {
  const DeviceLocationTimeout();
}

/// Location is permitted and enabled, but a fix still couldn't be obtained
/// (e.g. platform-reported hardware/driver error). Same recovery as
/// [DeviceLocationTimeout]: let the user retry.
class DeviceLocationUnavailable extends DeviceLocationResult {
  const DeviceLocationUnavailable();
}

/// Wraps `package:geolocator` behind the app's own result type, so the rest
/// of the app depends on [DeviceLocationResult] rather than geolocator's
/// exception/enum vocabulary directly.
///
/// This only ever reads the device's *current* position once per call — no
/// background tracking, no position stream. A location obtained here is
/// saved as a normal [Location] (see [CurrentLocationController]); moving
/// afterward doesn't update it, the same as any other saved pin.
class DeviceLocationService {
  DeviceLocationService({Duration? timeout}) : _timeout = timeout ?? const Duration(seconds: 20);

  final Duration _timeout;

  Future<DeviceLocationResult> getCurrentLocation() async {
    try {
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (!servicesEnabled) return const DeviceLocationServicesDisabled();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      switch (permission) {
        case LocationPermission.denied:
          return const DeviceLocationPermissionDenied();
        case LocationPermission.deniedForever:
          return const DeviceLocationPermissionDeniedForever();
        case LocationPermission.whileInUse:
        case LocationPermission.always:
        case LocationPermission.unableToDetermine:
          // unableToDetermine happens on browsers without the web
          // Permissions API — fall through and let getCurrentPosition
          // itself trigger the browser's native prompt.
          break;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: _timeout),
      );
      return DeviceLocationSuccess(latitude: position.latitude, longitude: position.longitude);
    } on TimeoutException {
      return const DeviceLocationTimeout();
    } on LocationServiceDisabledException {
      return const DeviceLocationServicesDisabled();
    } on PermissionDeniedException {
      return const DeviceLocationPermissionDenied();
    } catch (_) {
      return const DeviceLocationUnavailable();
    }
  }

  /// Opens the OS app-settings screen — the only recovery path for
  /// [DeviceLocationPermissionDeniedForever].
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Opens the OS location-services screen — the recovery path for
  /// [DeviceLocationServicesDisabled].
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
