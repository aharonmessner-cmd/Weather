/// Exceptions surfaced by the NWS API client.
///
/// The repository layer catches these and decides whether to fall back to
/// cached data; the UI layer should never need to know about NWS-specific
/// failure modes.
sealed class NwsException implements Exception {
  const NwsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No network connection, DNS failure, connection reset, etc.
class NwsNetworkException extends NwsException {
  const NwsNetworkException([super.message = 'Network error contacting the National Weather Service.']);
}

/// The request took too long to complete.
class NwsTimeoutException extends NwsException {
  const NwsTimeoutException([super.message = 'Timed out contacting the National Weather Service.']);
}

/// NWS returned 429, or otherwise indicated the client should back off.
class NwsRateLimitException extends NwsException {
  const NwsRateLimitException([super.message = 'Rate limited by the National Weather Service.']);
}

/// NWS returned 404 (e.g. no gridpoint/station at this location).
class NwsNotFoundException extends NwsException {
  const NwsNotFoundException([super.message = 'The requested NWS resource was not found.']);
}

/// NWS returned a 5xx error, or the service is otherwise unavailable.
class NwsServerException extends NwsException {
  const NwsServerException(this.statusCode, [String? message])
      : super(message ?? 'The National Weather Service returned an error.');

  final int statusCode;
}

/// NWS returned an unexpected status code not covered above.
class NwsHttpException extends NwsException {
  const NwsHttpException(this.statusCode, [String? message])
      : super(message ?? 'Unexpected response from the National Weather Service.');

  final int statusCode;
}

/// The response body was not valid JSON, or was missing fields required to
/// build the requested resource.
class NwsParseException extends NwsException {
  const NwsParseException([super.message = 'Could not understand the response from the National Weather Service.']);
}
