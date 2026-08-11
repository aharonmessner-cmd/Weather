import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/models/geocode_result.dart';
import '../../../core/services/geocoding/geocoding_exceptions.dart';

/// Every state the location-search sheet can be in. Search only ever runs
/// on explicit submit (see [LocationSearchController.search]) — never per
/// keystroke — so there's no "typing" state to model.
sealed class LocationSearchState {
  const LocationSearchState();
}

class LocationSearchIdle extends LocationSearchState {
  const LocationSearchIdle();
}

class LocationSearchLoading extends LocationSearchState {
  const LocationSearchLoading();
}

class LocationSearchResults extends LocationSearchState {
  const LocationSearchResults(this.results);

  final List<GeocodeResult> results;
}

class LocationSearchEmpty extends LocationSearchState {
  const LocationSearchEmpty();
}

class LocationSearchError extends LocationSearchState {
  const LocationSearchError(this.message);

  final String message;
}

class LocationSearchController extends Notifier<LocationSearchState> {
  @override
  LocationSearchState build() => const LocationSearchIdle();

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const LocationSearchIdle();
      return;
    }

    state = const LocationSearchLoading();
    try {
      final results = await ref.read(geocodingClientProvider).search(trimmed);
      state = results.isEmpty ? const LocationSearchEmpty() : LocationSearchResults(results);
    } on GeocodingException catch (e) {
      state = LocationSearchError(e.message);
    }
  }
}

final locationSearchControllerProvider = NotifierProvider<LocationSearchController, LocationSearchState>(
  LocationSearchController.new,
);
