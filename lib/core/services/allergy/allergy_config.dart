/// Static configuration for talking to Open-Meteo's Air Quality API
/// (https://open-meteo.com/en/docs/air-quality-api) — free, keyless, no
/// signup, used only for the Dust metric in Weather Details. Kept fully
/// separate from the NWS and Pirate Weather pipelines, the same way
/// `MinuteCastConfig` is; see the module doc on `AllergyRepository` for
/// why.
class AllergyConfig {
  const AllergyConfig._();

  static const String baseUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';

  static const Duration requestTimeout = Duration(seconds: 15);

  /// How often to proactively refresh while the Weather screen is
  /// visible and the location hasn't changed. Dust conditions change far
  /// more slowly than minute-by-minute precipitation, so this is
  /// deliberately much longer than `MinuteCastConfig.refreshInterval`.
  static const Duration refreshInterval = Duration(minutes: 30);

  /// Cached data older than this is not shown at all -- the card falls
  /// back to "unavailable" rather than risk showing a stale reading.
  static const Duration maxCacheAge = Duration(hours: 3);
}
