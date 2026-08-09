import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/models/location.dart';

const _uuid = Uuid();

/// Owns the list of saved locations and persists every change to the
/// [LocationStore]. The UI never writes to storage directly — it only ever
/// goes through this controller.
class LocationsController extends Notifier<List<Location>> {
  @override
  List<Location> build() {
    return ref.watch(locationStoreProvider).readAll();
  }

  Future<void> add({
    required String name,
    required double latitude,
    required double longitude,
    String? address,
    String? description,
    bool isFavorite = false,
  }) async {
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
  }

  Future<void> update(Location location) async {
    state = [
      for (final existing in state) existing.id == location.id ? location : existing,
    ];
    await _persist();
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
