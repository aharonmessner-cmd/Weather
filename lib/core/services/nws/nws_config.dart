import 'package:flutter/foundation.dart' show kReleaseMode;

/// Static configuration for talking to api.weather.gov.
///
/// NWS asks every client to identify itself with a descriptive User-Agent
/// containing a way to contact the developer, so they can reach out before
/// blocking abusive traffic. This is a small private app, so a name + email
/// is sufficient. Update [contactEmail] if this app changes hands.
///
/// NWS's own guidance is a User-Agent shaped like
/// `(app-identifier, contact-info)` — see
/// https://www.weather.gov/documentation/services-web-api under "Authentication".
class NwsConfig {
  const NwsConfig._();

  static const String baseUrl = 'https://api.weather.gov';

  static const String appName = 'PersonalWeatherApp';
  static const String contactEmail = 'chatty870@gmail.com';

  static const String userAgent = '($appName, $contactEmail)';

  static const Duration requestTimeout = Duration(seconds: 15);

  /// Development/debug mode for [NwsApiClient]: when true, every NWS
  /// request logs its HTTP method, endpoint URL, and resulting status code
  /// (or the error type, if the request failed before a response arrived).
  ///
  /// It never logs headers or response bodies — the User-Agent header
  /// contains [contactEmail], and response bodies can carry alert text and
  /// other content that doesn't need to end up in a log.
  ///
  /// Off by default. Enable it for a single run without touching source:
  ///   flutter run --dart-define=NWS_DEBUG_LOGGING=true
  ///
  /// `kReleaseMode` is checked in addition to the define so this can never
  /// stay on in a shipped release build, even if the define was left in a
  /// build script by mistake.
  static const bool debugLoggingEnabled =
      !kReleaseMode && bool.fromEnvironment('NWS_DEBUG_LOGGING');
}
