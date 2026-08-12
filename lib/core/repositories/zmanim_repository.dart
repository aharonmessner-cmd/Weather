import '../models/location.dart';
import '../models/zmanim/zmanim.dart';
import '../services/cache/zmanim_cache.dart';
import '../services/zmanim/zmanim_client.dart';
import '../utils/location_time.dart';

/// The single entry point the Zmanim feature uses to get today's halachic
/// times for a location. Mirrors `MinuteCastRepository`'s shape
/// (`getCached`/`fetchAndCache`) deliberately, but is a fully independent
/// type — nothing here is wired into `WeatherRepository`/`WeatherData`,
/// and a Zmanim failure never touches the NWS pipeline.
///
/// Both methods take [timeZone] explicitly (the location's IANA zone,
/// e.g. from `WeatherData.timeZone`) rather than trying to resolve one
/// themselves — `Location` itself doesn't own a time zone (see
/// `core/utils/location_time.dart`'s module doc), and Hebcal's `/zmanim`
/// endpoint requires a zone alongside bare lat/lon regardless. Callers
/// with no known zone yet should treat Zmanim as unavailable rather than
/// guessing the device's zone for a remote saved location.
abstract class ZmanimRepository {
  /// Returns *today's* (per [timeZone]) cached snapshot for [location], or
  /// null if none exists yet. Never touches the network.
  Future<Zmanim?> getCached(Location location, String timeZone);

  /// Fetches today's zmanim from Hebcal and persists them to the cache.
  /// Throws a [ZmanimException] on failure — callers should fall back to
  /// whatever [getCached] returned rather than treating this as fatal to
  /// the weather screen.
  Future<Zmanim> fetchAndCache(Location location, String timeZone);
}

class HebcalZmanimRepository implements ZmanimRepository {
  HebcalZmanimRepository({required ZmanimClient client, required ZmanimCache cache, DateTime Function()? now})
      : _client = client,
        _cache = cache,
        _now = now ?? DateTime.now;

  final ZmanimClient _client;
  final ZmanimCache _cache;
  final DateTime Function() _now;

  @override
  Future<Zmanim?> getCached(Location location, String timeZone) {
    return _cache.read(location.id, _locationDateString(timeZone));
  }

  @override
  Future<Zmanim> fetchAndCache(Location location, String timeZone) async {
    final date = _locationDateString(timeZone);
    final response = await _client.fetchZmanim(
      latitude: location.latitude,
      longitude: location.longitude,
      timeZone: timeZone,
      date: date,
    );

    final data = Zmanim(locationDate: date, location: location, generatedAt: _now(), times: response.times);
    await _cache.write(data);
    return data;
  }

  /// `YYYY-MM-DD` for "today" in [timeZone] — the calendar date this app
  /// asks Hebcal for and the key it caches under, deliberately computed
  /// from the *location's* zone rather than `DateTime.now().toLocal()`
  /// (the device's zone), since a saved location is not necessarily in
  /// the same time zone as the device checking it.
  String _locationDateString(String timeZone) {
    final local = resolveLocationTime(_now(), timeZone);
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
