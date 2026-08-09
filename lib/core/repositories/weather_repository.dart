import '../models/current_conditions.dart';
import '../models/daily_forecast.dart';
import '../models/hourly_forecast.dart';
import '../models/location.dart';
import '../models/nws/nws_alert.dart';
import '../models/nws/nws_forecast_period.dart';
import '../models/nws/nws_observation.dart';
import '../models/nws/nws_point.dart';
import '../models/nws/nws_station.dart';
import '../models/observation.dart';
import '../models/weather_alert.dart';
import '../models/weather_data.dart';
import '../services/cache/weather_cache.dart';
import '../services/nws/nws_api_client.dart';
import '../services/nws/nws_exceptions.dart';

/// The single entry point the UI/state layer uses to get weather for a
/// location. Hides NWS's multi-step resolution (point -> forecast/hourly/
/// stations/alerts) and the local cache behind two operations: read what we
/// already have, and go get something fresher.
abstract class WeatherRepository {
  /// Returns the last cached snapshot for [location], or null if none
  /// exists yet. Never touches the network.
  Future<WeatherData?> getCached(Location location);

  /// Fetches a fresh snapshot from NWS and persists it to the cache.
  /// Throws an [NwsException] on failure — callers should fall back to
  /// whatever [getCached] returned rather than treating this as fatal.
  Future<WeatherData> fetchAndCache(Location location);
}

class NwsWeatherRepository implements WeatherRepository {
  NwsWeatherRepository({required NwsApiClient client, required WeatherCache cache})
      : _client = client,
        _cache = cache;

  final NwsApiClient _client;
  final WeatherCache _cache;

  @override
  Future<WeatherData?> getCached(Location location) => _cache.read(location.id);

  @override
  Future<WeatherData> fetchAndCache(Location location) async {
    final pointJson = await _client.getPoints(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    final point = NwsPoint.tryParse(pointJson);
    if (point == null) throw const NwsParseException();

    // Kick every request off up front — Dart futures start running as soon
    // as they're created, so awaiting them below still runs them
    // concurrently. Forecast and hourly are awaited together via
    // Future.wait (rather than one-after-the-other) so that if one rejects
    // first, the other is still awaited internally instead of becoming an
    // unhandled Future error.
    final forecastFuture = _client.getForecast(point.forecastUrl);
    final hourlyFuture = _client.getHourlyForecast(point.forecastHourlyUrl);
    final observationFuture = _fetchLatestObservation(point.observationStationsUrl);
    final alertsFuture = _fetchAlerts(location);

    final forecastResults = await Future.wait([forecastFuture, hourlyFuture]);
    final forecastJson = forecastResults[0];
    final hourlyJson = forecastResults[1];

    final forecast = NwsForecast.tryParse(forecastJson);
    final hourlyForecast = NwsForecast.tryParse(hourlyJson);
    if (forecast == null || hourlyForecast == null) throw const NwsParseException();

    final daily = DailyForecastEntry.fromNwsPeriods(forecast.periods);
    final today = daily.isNotEmpty ? daily.first : null;
    final NwsForecastPeriod? currentPeriod = forecast.periods.isNotEmpty ? forecast.periods.first : null;

    final observation = await observationFuture;
    final alerts = await alertsFuture;

    final data = WeatherData(
      location: location,
      current: CurrentConditions.build(
        observation: observation,
        currentPeriod: currentPeriod,
        today: today,
      ),
      observation: observation,
      hourly: hourlyForecast.periods.map(HourlyForecastEntry.fromNws).toList(),
      daily: daily,
      alerts: alerts,
      fetchedAt: DateTime.now(),
    );

    await _cache.write(location.id, data);
    return data;
  }

  /// Observation stations are physical hardware and go offline or report
  /// gaps often. Current conditions should still work (falling back to the
  /// forecast) when this fails, so failures here are swallowed rather than
  /// propagated.
  Future<Observation?> _fetchLatestObservation(String stationsUrl) async {
    List<NwsStation> stations;
    try {
      final stationsJson = await _client.getObservationStations(stationsUrl);
      stations = NwsStationsResponse.tryParse(stationsJson).stations;
    } on NwsException {
      return null;
    }

    // Stations are ordered nearest-first; try a few in case the closest
    // one hasn't reported recently.
    for (final station in stations.take(3)) {
      try {
        final obsJson = await _client.getLatestObservation(station.stationId);
        final raw = NwsObservation.tryParse(obsJson);
        if (raw == null || raw.temperatureCelsius == null) continue;
        return Observation.fromNws(raw, stationId: station.stationId, stationName: station.name);
      } on NwsException {
        continue;
      }
    }
    return null;
  }

  /// Alerts are supplementary to the core forecast; a failure here
  /// shouldn't take down the whole weather screen.
  Future<List<WeatherAlert>> _fetchAlerts(Location location) async {
    try {
      final alertsJson = await _client.getActiveAlertsForPoint(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      final response = NwsAlertsResponse.tryParse(alertsJson);
      return response.alerts.map(WeatherAlert.fromNws).toList();
    } on NwsException {
      return const [];
    }
  }
}
