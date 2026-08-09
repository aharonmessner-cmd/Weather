import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/weather_data.dart';

/// Local persistence for the last successfully fetched [WeatherData] per
/// location, so the app has something to show immediately on launch and
/// can keep working (in a visibly stale way) when NWS is unreachable.
///
/// Deliberately simple for V1: one JSON blob per location in
/// [SharedPreferences]. If this needs to scale up later (e.g. many
/// locations, richer queries), swap the storage backend here without
/// touching callers.
class WeatherCache {
  WeatherCache(this._prefs);

  final SharedPreferences _prefs;

  static const _keyPrefix = 'weather_cache_v1_';

  Future<WeatherData?> read(String locationId) async {
    final raw = _prefs.getString('$_keyPrefix$locationId');
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return WeatherData.tryFromJson(json);
    } on FormatException {
      return null;
    }
  }

  Future<void> write(String locationId, WeatherData data) async {
    await _prefs.setString('$_keyPrefix$locationId', jsonEncode(data.toJson()));
  }

  Future<void> clear(String locationId) async {
    await _prefs.remove('$_keyPrefix$locationId');
  }
}
