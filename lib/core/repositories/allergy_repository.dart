import '../models/allergy/allergy_data.dart';
import '../models/location.dart';
import '../services/allergy/allergy_client.dart';
import '../services/cache/allergy_cache.dart';

/// The single entry point the Allergies feature uses to get dust
/// conditions for a location. Mirrors `MinuteCastRepository`'s shape
/// (`getCached`/`fetchAndCache`) deliberately, but is a fully independent
/// type — nothing here is wired into `WeatherRepository`/`WeatherData` or
/// `MinuteCastRepository`, and an Allergy failure never touches either
/// pipeline.
abstract class AllergyRepository {
  /// Returns the last cached snapshot for [location], or null if none
  /// exists yet. Never touches the network. Does not filter by age --
  /// that's the caller's job (see `AllergyController`).
  Future<AllergyData?> getCached(Location location);

  /// Fetches a fresh snapshot from Open-Meteo and persists it to the
  /// cache. Throws an [AllergyException] on failure -- callers should
  /// fall back to whatever [getCached] returned rather than treating this
  /// as fatal to the weather screen.
  Future<AllergyData> fetchAndCache(Location location);
}

class OpenMeteoAllergyRepository implements AllergyRepository {
  OpenMeteoAllergyRepository({
    required AllergyClient client,
    required AllergyCache cache,
    DateTime Function()? now,
  })  : _client = client,
        _cache = cache,
        _now = now ?? DateTime.now;

  final AllergyClient _client;
  final AllergyCache _cache;
  final DateTime Function() _now;

  @override
  Future<AllergyData?> getCached(Location location) => _cache.read(location.id);

  @override
  Future<AllergyData> fetchAndCache(Location location) async {
    final response = await _client.fetchCurrent(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    final data = AllergyData(
      generatedAt: _now(),
      location: location,
      source: AllergySource.openMeteo,
      dustMicrogramsPerCubicMeter: response.dustMicrogramsPerCubicMeter,
    );

    await _cache.write(location.id, data);
    return data;
  }
}
