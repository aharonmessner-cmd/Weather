/// Exceptions surfaced by [MinuteCastClient].
///
/// Mirrors `core/services/nws/nws_exceptions.dart` — the repository layer
/// catches these and decides what to do (fall back to cache, or report
/// "unavailable"); nothing above the repository ever sees a MinuteCast
/// exception directly, since a MinuteCast failure must never break the
/// main weather screen.
sealed class MinuteCastException implements Exception {
  const MinuteCastException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No API key is configured (see [MinuteCastConfig.apiKey]) — distinct
/// from a network failure so the repository can treat "not set up" as a
/// quiet, permanent "unavailable" rather than something worth retrying.
class MinuteCastNotConfiguredException extends MinuteCastException {
  const MinuteCastNotConfiguredException([super.message = 'MinuteCast is not configured.']);
}

/// No network connection, DNS failure, connection reset, etc.
class MinuteCastNetworkException extends MinuteCastException {
  const MinuteCastNetworkException([super.message = 'Network error contacting the precipitation nowcast service.']);
}

/// The request took too long to complete.
class MinuteCastTimeoutException extends MinuteCastException {
  const MinuteCastTimeoutException([super.message = 'Timed out contacting the precipitation nowcast service.']);
}

/// Pirate Weather returned 429, or otherwise indicated the client should
/// back off.
class MinuteCastRateLimitException extends MinuteCastException {
  const MinuteCastRateLimitException([super.message = 'Rate limited by the precipitation nowcast service.']);
}

/// Pirate Weather returned a 5xx error, or an unexpected status code.
class MinuteCastServerException extends MinuteCastException {
  const MinuteCastServerException(this.statusCode, [String? message])
      : super(message ?? 'The precipitation nowcast service returned an error.');

  final int statusCode;
}

/// The response body was not valid JSON, or was missing the `minutely`
/// data this app relies on.
class MinuteCastParseException extends MinuteCastException {
  const MinuteCastParseException([super.message = 'Could not understand the precipitation nowcast response.']);
}
