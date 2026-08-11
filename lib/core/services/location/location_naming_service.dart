import '../../models/nws/nws_point.dart';
import '../nws/nws_api_client.dart';
import '../nws/nws_exceptions.dart';

/// Outcomes of [LocationNamingService.resolve].
sealed class LocationNamingResult {
  const LocationNamingResult();
}

/// NWS resolved this point. [cityState] is the "City, ST" label built from
/// `relativeLocation` when NWS provided one — occasionally it doesn't (a
/// remote gridpoint with no nearby named place), in which case [cityState]
/// is null and the caller should fall back to a generic name. Either way,
/// weather works here: the point itself resolved.
class LocationNamingResolved extends LocationNamingResult {
  const LocationNamingResolved(this.cityState);

  final String? cityState;
}

/// NWS has no coverage at this point (outside the US, or open ocean) — the
/// "unavailable location" case. Weather can never load here, so the caller
/// should stop rather than save a location that will only ever show an
/// error.
class LocationNamingUnavailable extends LocationNamingResult {
  const LocationNamingUnavailable();
}

/// A transient failure while resolving (network, timeout, server error,
/// unparseable response) — distinct from [LocationNamingUnavailable]
/// because retrying may succeed.
class LocationNamingFailed extends LocationNamingResult {
  const LocationNamingFailed();
}

/// Resolves a display name for raw coordinates via NWS's own `/points`
/// response, instead of a second geocoding lookup — see [NwsPoint]'s
/// `relativeCityName`/`relativeCityState`, which every point resolution
/// already includes. Used by "Use My Location", where there's no search
/// result to name the place with (unlike the search flow, which already has
/// a clean name from the geocoder).
class LocationNamingService {
  LocationNamingService(this._client);

  final NwsApiClient _client;

  Future<LocationNamingResult> resolve({required double latitude, required double longitude}) async {
    try {
      final json = await _client.getPoints(latitude: latitude, longitude: longitude);
      final point = NwsPoint.tryParse(json);
      if (point == null) return const LocationNamingFailed();

      final city = point.relativeCityName;
      final state = point.relativeCityState;
      if (city == null) return const LocationNamingResolved(null);
      return LocationNamingResolved(state == null ? city : '$city, $state');
    } on NwsNotFoundException {
      return const LocationNamingUnavailable();
    } on NwsException {
      return const LocationNamingFailed();
    }
  }
}
