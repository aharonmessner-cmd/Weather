/// Static configuration for talking to api.weather.gov.
///
/// NWS asks every client to identify itself with a descriptive User-Agent
/// containing a way to contact the developer, so they can reach out before
/// blocking abusive traffic. This is a small private app, so a name + email
/// is sufficient. Update [contactEmail] if this app changes hands.
class NwsConfig {
  const NwsConfig._();

  static const String baseUrl = 'https://api.weather.gov';

  static const String appName = 'PersonalWeatherApp';
  static const String contactEmail = 'chatty870@gmail.com';

  static const String userAgent = '($appName, $contactEmail)';

  static const Duration requestTimeout = Duration(seconds: 15);
}
