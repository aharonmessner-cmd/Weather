import '../models/location.dart';
import '../models/minutecast/minute_cast.dart';
import '../models/minutecast/minute_precipitation_forecast.dart';
import '../services/cache/minutecast_cache.dart';
import '../services/minutecast/minutecast_client.dart';

/// The single entry point the MinuteCast feature uses to get precipitation
/// nowcast data for a location. Mirrors `WeatherRepository`'s shape
/// (`getCached`/`fetchAndCache`) deliberately, but is a fully independent
/// type — nothing here is wired into `WeatherRepository`/`WeatherData`,
/// and a MinuteCast failure never touches the NWS pipeline.
abstract class MinuteCastRepository {
  /// Returns the last cached snapshot for [location], or null if none
  /// exists yet. Never touches the network. Does not filter by age —
  /// that's the caller's job (see `MinuteCastController`), the same
  /// division of responsibility as `WeatherRepository.getCached`.
  Future<MinuteCast?> getCached(Location location);

  /// Fetches a fresh snapshot from Pirate Weather and persists it to the
  /// cache. Throws a [MinuteCastException] on failure — callers should
  /// fall back to whatever [getCached] returned rather than treating this
  /// as fatal to the weather screen.
  Future<MinuteCast> fetchAndCache(Location location);
}

class PirateWeatherMinuteCastRepository implements MinuteCastRepository {
  PirateWeatherMinuteCastRepository({
    required MinuteCastClient client,
    required MinuteCastCache cache,
    DateTime Function()? now,
  })  : _client = client,
        _cache = cache,
        _now = now ?? DateTime.now;

  final MinuteCastClient _client;
  final MinuteCastCache _cache;
  final DateTime Function() _now;

  @override
  Future<MinuteCast?> getCached(Location location) => _cache.read(location.id);

  @override
  Future<MinuteCast> fetchAndCache(Location location) async {
    final response = await _client.fetchMinutely(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    final data = MinuteCast(
      generatedAt: _now(),
      location: location,
      minutes: response.minutes.map(MinutePrecipitationForecast.fromPirateWeather).toList(),
      source: MinuteCastSource.pirateWeather,
      uvIndex: response.uvIndex,
    );

    await _cache.write(location.id, data);
    return data;
  }
}
