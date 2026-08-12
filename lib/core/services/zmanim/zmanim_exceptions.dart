/// Exceptions surfaced by [ZmanimClient].
///
/// Mirrors `core/services/minutecast/minutecast_exceptions.dart` — the
/// repository layer catches these and decides what to do (fall back to
/// cache, or report "unavailable"); nothing above the repository ever
/// sees a Zmanim exception directly, since a Zmanim failure must never
/// break the main weather screen. Unlike MinuteCast, Hebcal's `/zmanim`
/// endpoint needs no API key, so there is no "not configured" variant.
sealed class ZmanimException implements Exception {
  const ZmanimException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No network connection, DNS failure, connection reset, etc.
class ZmanimNetworkException extends ZmanimException {
  const ZmanimNetworkException([super.message = 'Network error contacting the Zmanim service.']);
}

/// The request took too long to complete.
class ZmanimTimeoutException extends ZmanimException {
  const ZmanimTimeoutException([super.message = 'Timed out contacting the Zmanim service.']);
}

/// Hebcal returned 429, or otherwise indicated the client should back off.
class ZmanimRateLimitException extends ZmanimException {
  const ZmanimRateLimitException([super.message = 'Rate limited by the Zmanim service.']);
}

/// Hebcal returned a 5xx error, or an unexpected status code.
class ZmanimServerException extends ZmanimException {
  const ZmanimServerException(this.statusCode, [String? message])
      : super(message ?? 'The Zmanim service returned an error.');

  final int statusCode;
}

/// The response body was not valid JSON, or had no recognizable zmanim.
class ZmanimParseException extends ZmanimException {
  const ZmanimParseException([super.message = 'Could not understand the Zmanim response.']);
}
