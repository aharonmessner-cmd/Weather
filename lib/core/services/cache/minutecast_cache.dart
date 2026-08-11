import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/minutecast/minute_cast.dart';

/// Local persistence for the last successfully fetched [MinuteCast] per
/// location — its own key namespace, entirely separate from
/// [WeatherCache]. Mirrors that class's shape; see its doc for the
/// rationale (one JSON blob per location, swappable storage backend
/// later without touching callers).
class MinuteCastCache {
  MinuteCastCache(this._prefs);

  final SharedPreferences _prefs;

  static const _keyPrefix = 'minutecast_cache_v1_';

  Future<MinuteCast?> read(String locationId) async {
    final raw = _prefs.getString('$_keyPrefix$locationId');
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return MinuteCast.tryFromJson(json);
    } on FormatException {
      return null;
    }
  }

  Future<void> write(String locationId, MinuteCast data) async {
    await _prefs.setString('$_keyPrefix$locationId', jsonEncode(data.toJson()));
  }

  Future<void> clear(String locationId) async {
    await _prefs.remove('$_keyPrefix$locationId');
  }
}
