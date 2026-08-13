/// Exceptions surfaced by [AllergyClient].
///
/// Mirrors `core/services/minutecast/minutecast_exceptions.dart` — the
/// repository layer catches these and decides what to do (fall back to
/// cache, or report "unavailable"); nothing above the repository ever
/// sees an Allergy exception directly, since an Allergy failure must
/// never break the main weather screen.
sealed class AllergyException implements Exception {
  const AllergyException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No network connection, DNS failure, connection reset, etc.
class AllergyNetworkException extends AllergyException {
  const AllergyNetworkException([super.message = 'Network error contacting the air quality service.']);
}

/// The request took too long to complete.
class AllergyTimeoutException extends AllergyException {
  const AllergyTimeoutException([super.message = 'Timed out contacting the air quality service.']);
}

/// Open-Meteo returned 429, or otherwise indicated the client should back
/// off.
class AllergyRateLimitException extends AllergyException {
  const AllergyRateLimitException([super.message = 'Rate limited by the air quality service.']);
}

/// Open-Meteo returned a 5xx error, or an unexpected status code.
class AllergyServerException extends AllergyException {
  const AllergyServerException(this.statusCode, [String? message])
      : super(message ?? 'The air quality service returned an error.');

  final int statusCode;
}

/// The response body was not valid JSON, or was missing the `current`
/// block this app relies on.
class AllergyParseException extends AllergyException {
  const AllergyParseException([super.message = 'Could not understand the air quality response.']);
}
