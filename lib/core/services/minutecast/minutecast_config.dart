/// Static configuration for talking to Pirate Weather
/// (https://pirateweather.net) — a free, keyless-to-sign-up-for,
/// genuine short-term precipitation nowcast, used only as a secondary
/// source alongside (never instead of) NWS. See the module doc on
/// `MinuteCastRepository` for why this is kept fully separate from the
/// NWS pipeline.
///
/// The API key is supplied at build time and never committed:
///   flutter run --dart-define=PIRATE_WEATHER_API_KEY=your-key-here
/// With no key configured, [apiKey] is empty and [MinuteCastClient]
/// throws [MinuteCastNotConfiguredException] before making any request —
/// the MinuteCast section simply doesn't appear, the rest of the app is
/// unaffected.
class MinuteCastConfig {
  const MinuteCastConfig._();

  static const String baseUrl = 'https://api.pirateweather.net/forecast';

  static const String apiKey = String.fromEnvironment('PIRATE_WEATHER_API_KEY');

  static bool get isConfigured => apiKey.isNotEmpty;

  static const Duration requestTimeout = Duration(seconds: 15);

  /// How often to proactively refresh while the Weather screen is
  /// visible and the location hasn't changed — short, because
  /// minute-by-minute precipitation data ages far faster than the
  /// hourly/daily NWS data it sits next to.
  static const Duration refreshInterval = Duration(minutes: 5);

  /// Cached data older than this is not shown at all — the section falls
  /// back to "unavailable" rather than risk showing a "starting in 3 min"
  /// that's actually long past. Deliberately tighter than
  /// [refreshInterval] gives headroom for: this is the hard cutoff, not
  /// the target cadence.
  static const Duration maxCacheAge = Duration(minutes: 20);
}
