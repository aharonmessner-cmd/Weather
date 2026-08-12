import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/zmanim/zmanim.dart';

/// Local persistence for the last successfully fetched [Zmanim] snapshot,
/// one per (location, location-local calendar date) — its own key
/// namespace, entirely separate from [WeatherCache]/[MinuteCastCache].
/// Keying by date directly (rather than overwriting a single per-location
/// entry) means yesterday's snapshot simply isn't looked up once the
/// calendar date rolls over; nothing needs to actively evict it.
class ZmanimCache {
  ZmanimCache(this._prefs);

  final SharedPreferences _prefs;

  static const _keyPrefix = 'zmanim_cache_v1_';

  String _key(String locationId, String locationDate) => '$_keyPrefix${locationId}_$locationDate';

  Future<Zmanim?> read(String locationId, String locationDate) async {
    final raw = _prefs.getString(_key(locationId, locationDate));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return Zmanim.tryFromJson(json);
    } on FormatException {
      return null;
    }
  }

  Future<void> write(Zmanim data) async {
    await _prefs.setString(_key(data.location.id, data.locationDate), jsonEncode(data.toJson()));
  }
}
