/// Small, defensive JSON-parsing helpers shared by the NWS raw response
/// models.
///
/// NWS responses are inconsistent about which fields are present (a closed
/// station might be missing wind data; a coastal gridpoint might have no
/// precipitation probability) and represent quantities in two different
/// shapes:
///   - a bare value: `"temperature": 72`
///   - a "quantitative value" object: `"temperature": {"unitCode": "...", "value": 22.2}`
///
/// These helpers never throw on missing or malformed input; they return
/// `null` so callers can decide how to present "unknown" in the UI instead
/// of crashing the whole parse over one bad field.
library;

double? nwsAsDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? nwsAsInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.round();
  return null;
}

String? nwsAsString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

bool? nwsAsBool(dynamic value) {
  if (value is bool) return value;
  return null;
}

DateTime? nwsAsDateTime(dynamic value) {
  final str = nwsAsString(value);
  if (str == null) return null;
  return DateTime.tryParse(str);
}

/// Extracts the numeric `value` from an NWS "quantitative value" object,
/// e.g. `{"unitCode": "wmoUnit:degC", "value": 22.2, "qualityControl": "V"}`.
/// Falls back to treating [value] as a bare number for endpoints that don't
/// wrap their values (forecast period temperatures, for example).
double? nwsQuantity(dynamic value) {
  if (value is Map) {
    return nwsAsDouble(value['value']);
  }
  return nwsAsDouble(value);
}

List<Map<String, dynamic>> nwsAsMapList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList();
}
