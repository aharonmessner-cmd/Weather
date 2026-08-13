import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/allergy/allergy_data.dart';

/// Local persistence for the last successfully fetched [AllergyData] per
/// location — its own key namespace, entirely separate from
/// [WeatherCache]/[MinuteCastCache]. Mirrors `MinuteCastCache`'s shape;
/// see its doc for the rationale.
class AllergyCache {
  AllergyCache(this._prefs);

  final SharedPreferences _prefs;

  static const _keyPrefix = 'allergy_cache_v1_';

  Future<AllergyData?> read(String locationId) async {
    final raw = _prefs.getString('$_keyPrefix$locationId');
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return AllergyData.tryFromJson(json);
    } on FormatException {
      return null;
    }
  }

  Future<void> write(String locationId, AllergyData data) async {
    await _prefs.setString('$_keyPrefix$locationId', jsonEncode(data.toJson()));
  }

  Future<void> clear(String locationId) async {
    await _prefs.remove('$_keyPrefix$locationId');
  }
}
