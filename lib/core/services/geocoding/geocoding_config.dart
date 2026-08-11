import '../../app_contact.dart';

/// Static configuration for talking to Nominatim (OpenStreetMap's public
/// geocoding search).
///
/// Nominatim is free and keyless, but its usage policy
/// (https://operations.osmfoundation.org/policies/nominatim/) asks every
/// client for a descriptive User-Agent and to keep request volume light —
/// the same spirit as NWS's own User-Agent requirement, so this reuses the
/// same [AppContact] identity. This app only searches when the user
/// explicitly submits a query (never per-keystroke), which comfortably
/// stays within "moderate, directly user-triggered use."
class GeocodingConfig {
  const GeocodingConfig._();

  static const String baseUrl = 'https://nominatim.openstreetmap.org';

  static const String userAgent = '${AppContact.appName}/1.0 (${AppContact.contactEmail})';

  static const Duration requestTimeout = Duration(seconds: 15);

  /// Weather data only exists for the US via NWS, so results outside it
  /// would be dead ends — restricting the search itself keeps the results
  /// list free of places this app could never show weather for.
  static const String countryCodes = 'us';

  static const int resultLimit = 8;
}
