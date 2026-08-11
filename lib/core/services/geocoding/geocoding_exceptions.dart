/// Exceptions surfaced by [NominatimGeocodingClient].
///
/// Mirrors the shape of `core/services/nws/nws_exceptions.dart` — the
/// search UI catches these and decides what to show, the same way the
/// weather screens already do for NWS failures.
sealed class GeocodingException implements Exception {
  const GeocodingException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No network connection, DNS failure, connection reset, etc.
class GeocodingNetworkException extends GeocodingException {
  const GeocodingNetworkException([super.message = 'Network error while searching for that location.']);
}

/// The request took too long to complete.
class GeocodingTimeoutException extends GeocodingException {
  const GeocodingTimeoutException([super.message = 'Timed out while searching for that location.']);
}

/// Nominatim returned 429, or otherwise indicated the client should back
/// off. Search is user-triggered (on submit, never per-keystroke) so this
/// should be rare, but a shared/slow connection or a rapid double-submit
/// can still trigger it.
class GeocodingRateLimitException extends GeocodingException {
  const GeocodingRateLimitException([super.message = 'Too many location searches — wait a moment and try again.']);
}

/// Nominatim returned a 5xx error, or the service is otherwise unavailable.
class GeocodingServerException extends GeocodingException {
  const GeocodingServerException(this.statusCode, [String? message])
      : super(message ?? 'The location search service returned an error.');

  final int statusCode;
}

/// The response body was not valid JSON, or was in an unexpected shape.
class GeocodingParseException extends GeocodingException {
  const GeocodingParseException([super.message = 'Could not understand the location search results.']);
}
