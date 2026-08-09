import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/location.dart';

/// Local persistence for the user's saved [Location]s.
///
/// A flat JSON array in [SharedPreferences] is intentionally simple for a
/// handful of personal locations; if device geolocation is added later,
/// this is where a "current location" entry would be merged in without
/// changing the store's public shape.
class LocationStore {
  LocationStore(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'saved_locations_v1';

  List<Location> readAll() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Location.tryFromJson)
          .whereType<Location>()
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> writeAll(List<Location> locations) async {
    await _prefs.setString(_key, jsonEncode(locations.map((l) => l.toJson()).toList()));
  }
}
