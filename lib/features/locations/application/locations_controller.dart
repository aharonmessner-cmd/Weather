import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/models/location.dart';

const _uuid = Uuid();

/// Two saved locations within this distance of each other are treated as
/// the same place, regardless of exact floating-point coordinates — GPS,
/// a geocoder, and manual entry for "the same town" will rarely produce
/// bit-identical lat/lon. 1km is comfortably smaller than an NWS forecast
/// grid cell (~2.5km), so anything inside it gets the same forecast anyway.
const _duplicateToleranceMeters = 1000.0;

/// The result of [LocationsController.add] or [LocationsController.update]:
/// either a genuinely new/changed location, or the existing saved location
/// that was already within [_duplicateToleranceMeters] of the requested
/// coordinates — callers use [wasDuplicate] to tell the user which
/// happened instead of silently creating a second pin for the same place.
class SaveLocationResult {
  const SaveLocationResult({required this.location, required this.wasDuplicate});

  final Location location;
  final bool wasDuplicate;
}

/// Owns the list of saved locations and persists every change to the
/// [LocationStore]. The UI never writes to storage directly — it only ever
/// goes through this controller.
class LocationsController extends Notifier<List<Location>> {
  @override
  List<Location> build() {
    return ref.watch(locationStoreProvider).readAll();
  }

  /// Adds a new location — unless one already exists within
  /// [_duplicateToleranceMeters], in which case that existing location is
  /// returned instead ([SaveLocationResult.wasDuplicate] is true) and
  /// nothing new is saved.
  Future<SaveLocationResult> add({
    required String name,
    required double latitude,
    required double longitude,
    String? address,
    String? description,
    bool isFavorite = false,
  }) async {
    final duplicate = _findNearbyDuplicate(latitude, longitude);
    if (duplicate != null) return SaveLocationResult(location: duplicate, wasDuplicate: true);

    final location = Location(
      id: _uuid.v4(),
      name: name,
      latitude: latitude,
      longitude: longitude,
      address: address,
      description: description,
      isFavorite: isFavorite || state.isEmpty,
    );
    state = [...state, location];
    await _persist();
    return SaveLocationResult(location: location, wasDuplicate: false);
  }

  /// Updates an existing saved location — unless the new coordinates land
  /// within [_duplicateToleranceMeters] of a *different* saved location, in
  /// which case that other location is returned instead
  /// ([SaveLocationResult.wasDuplicate] is true) and this edit is
  /// discarded rather than creating two entries for the same place.
  Future<SaveLocationResult> update(Location location) async {
    final duplicate = _findNearbyDuplicate(location.latitude, location.longitude, excludeId: location.id);
    if (duplicate != null) return SaveLocationResult(location: duplicate, wasDuplicate: true);

    state = [
      for (final existing in state) existing.id == location.id ? location : existing,
    ];
    await _persist();
    return SaveLocationResult(location: location, wasDuplicate: false);
  }

  Location? _findNearbyDuplicate(double latitude, double longitude, {String? excludeId}) {
    for (final existing in state) {
      if (existing.id == excludeId) continue;
      final meters = Geolocator.distanceBetween(existing.latitude, existing.longitude, latitude, longitude);
      if (meters <= _duplicateToleranceMeters) return existing;
    }
    return null;
  }

  Future<void> remove(String id) async {
    final wasFavorite = state.any((l) => l.id == id && l.isFavorite);
    final remaining = state.where((l) => l.id != id).toList();
    // Keep exactly one favorite (when any locations remain) so the weather
    // screen always has an unambiguous default to show.
    state = (wasFavorite && remaining.isNotEmpty)
        ? [
            for (var i = 0; i < remaining.length; i++) remaining[i].copyWith(isFavorite: i == 0),
          ]
        : remaining;
    await _persist();
  }

  Future<void> setFavorite(String id) async {
    state = [for (final l in state) l.copyWith(isFavorite: l.id == id)];
    await _persist();
  }

  Future<void> _persist() => ref.read(locationStoreProvider).writeAll(state);
}

final locationsControllerProvider = NotifierProvider<LocationsController, List<Location>>(
  LocationsController.new,
);

/// The location currently shown on the weather dashboard. Null means "no
/// explicit selection yet" — [selectedLocationProvider] resolves that to
/// the favorite (or first) saved location.
final selectedLocationIdProvider = StateProvider<String?>((ref) => null);

/// The [Location] the weather screen should display: the explicitly
/// selected one if it still exists, otherwise the favorite, otherwise the
/// first saved location, otherwise null (no locations saved yet).
final selectedLocationProvider = Provider<Location?>((ref) {
  final locations = ref.watch(locationsControllerProvider);
  if (locations.isEmpty) return null;

  final selectedId = ref.watch(selectedLocationIdProvider);
  if (selectedId != null) {
    for (final location in locations) {
      if (location.id == selectedId) return location;
    }
  }

  for (final location in locations) {
    if (location.isFavorite) return location;
  }
  return locations.first;
});
