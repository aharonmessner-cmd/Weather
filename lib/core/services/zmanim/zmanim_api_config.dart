/// Static configuration for talking to Hebcal's `/zmanim` REST API
/// (https://www.hebcal.com/home/1663/zmanim-halachic-times-api) — used
/// only as a self-contained, secondary source alongside (never mixed
/// into) the NWS weather pipeline. No API key is required or supported;
/// Hebcal's zmanim endpoint is open. Content is licensed CC-BY 4.0, which
/// is why the Settings screen carries a small Hebcal attribution line.
class ZmanimApiConfig {
  const ZmanimApiConfig._();

  static const String baseUrl = 'https://www.hebcal.com/zmanim';

  static const Duration requestTimeout = Duration(seconds: 15);

  /// Zmanim only change meaningfully once per calendar day, so cached
  /// data is treated as fresh for far longer than MinuteCast's — this is
  /// only a safety net against a stuck/corrupt cache entry, not a
  /// meaningful "go re-fetch" cadence. Real refreshes are driven by
  /// location/date/configuration changes, not by age.
  static const Duration maxCacheAge = Duration(hours: 25);
}
