import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/models/location.dart';
import '../../../core/services/location/device_location_service.dart';
import '../../../core/services/location/location_naming_service.dart';
import 'locations_controller.dart';

/// Every state the "Use My Location" flow can be in.
sealed class CurrentLocationState {
  const CurrentLocationState();
}

class CurrentLocationIdle extends CurrentLocationState {
  const CurrentLocationIdle();
}

class CurrentLocationLoading extends CurrentLocationState {
  const CurrentLocationLoading();
}

class CurrentLocationSucceeded extends CurrentLocationState {
  const CurrentLocationSucceeded({required this.location, required this.wasDuplicate});

  final Location location;

  /// True when this coordinates matched an already-saved location (within
  /// [LocationsController]'s duplicate tolerance) rather than creating a
  /// new one — the UI uses this to say "already saved" instead of "added".
  final bool wasDuplicate;
}

enum CurrentLocationFailureReason {
  permissionDenied,
  permissionDeniedForever,
  servicesDisabled,
  timeout,
  unavailable,
  nwsUnavailable,
  nwsTemporaryError,
}

class CurrentLocationFailed extends CurrentLocationState {
  const CurrentLocationFailed(this.reason);

  final CurrentLocationFailureReason reason;
}

/// Drives "Use My Location" end to end: device coordinates ->
/// NWS-resolved display name -> saved (and selected) via the existing
/// [LocationsController] -> ready for the weather pipeline like any other
/// saved location.
///
/// Every step that can fail maps to a specific [CurrentLocationFailureReason]
/// rather than a generic error, so the UI can show the right recovery
/// action (retry vs. open Settings) for each one.
class CurrentLocationController extends Notifier<CurrentLocationState> {
  @override
  CurrentLocationState build() => const CurrentLocationIdle();

  Future<void> useMyLocation() async {
    state = const CurrentLocationLoading();

    final coordinates = await _acquireCoordinates();
    if (coordinates == null) return; // state already set to CurrentLocationFailed

    final (latitude, longitude) = coordinates;
    final displayName = await _resolveDisplayName(latitude, longitude);
    if (displayName == null) return; // state already set to CurrentLocationFailed

    final saveResult = await ref.read(locationsControllerProvider.notifier).add(
          name: displayName,
          latitude: latitude,
          longitude: longitude,
        );
    ref.read(selectedLocationIdProvider.notifier).state = saveResult.location.id;
    state = CurrentLocationSucceeded(location: saveResult.location, wasDuplicate: saveResult.wasDuplicate);
  }

  Future<(double, double)?> _acquireCoordinates() async {
    final result = await ref.read(deviceLocationServiceProvider).getCurrentLocation();
    switch (result) {
      case DeviceLocationSuccess(:final latitude, :final longitude):
        return (latitude, longitude);
      case DeviceLocationPermissionDenied():
        state = const CurrentLocationFailed(CurrentLocationFailureReason.permissionDenied);
      case DeviceLocationPermissionDeniedForever():
        state = const CurrentLocationFailed(CurrentLocationFailureReason.permissionDeniedForever);
      case DeviceLocationServicesDisabled():
        state = const CurrentLocationFailed(CurrentLocationFailureReason.servicesDisabled);
      case DeviceLocationTimeout():
        state = const CurrentLocationFailed(CurrentLocationFailureReason.timeout);
      case DeviceLocationUnavailable():
        state = const CurrentLocationFailed(CurrentLocationFailureReason.unavailable);
    }
    return null;
  }

  Future<String?> _resolveDisplayName(double latitude, double longitude) async {
    final result = await ref.read(locationNamingServiceProvider).resolve(latitude: latitude, longitude: longitude);
    switch (result) {
      case LocationNamingResolved(:final cityState):
        return cityState ?? 'Current Location';
      case LocationNamingUnavailable():
        state = const CurrentLocationFailed(CurrentLocationFailureReason.nwsUnavailable);
      case LocationNamingFailed():
        state = const CurrentLocationFailed(CurrentLocationFailureReason.nwsTemporaryError);
    }
    return null;
  }
}

final currentLocationControllerProvider = NotifierProvider<CurrentLocationController, CurrentLocationState>(
  CurrentLocationController.new,
);
