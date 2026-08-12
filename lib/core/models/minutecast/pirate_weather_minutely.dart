/// Raw parse of Pirate Weather's `/forecast` response, scoped to the
/// `minutely` block this app actually uses. Mirrors the shape of
/// `core/models/nws/` — this is the *only* place that knows Pirate
/// Weather's field names; everything past this layer talks in
/// [MinutePrecipitationForecast]/[MinuteCast].
class PirateWeatherMinuteEntry {
  const PirateWeatherMinuteEntry({
    required this.time,
    this.precipIntensity,
    this.precipProbability,
    this.precipType,
  });

  /// UTC instant (Pirate Weather sends Unix seconds — inherently
  /// timezone-less, so no conversion is needed or possible at this
  /// layer).
  final DateTime time;

  /// Liquid-equivalent rate in mm/h (requested via `units=si`).
  final double? precipIntensity;

  /// 0.0-1.0.
  final double? precipProbability;

  /// `"rain"` | `"snow"` | `"sleet"` | null (Pirate Weather omits this
  /// field entirely for minutes with no precipitation).
  final String? precipType;

  static PirateWeatherMinuteEntry? tryParse(Map<String, dynamic> json) {
    final rawTime = json['time'];
    if (rawTime is! num) return null;
    return PirateWeatherMinuteEntry(
      time: DateTime.fromMillisecondsSinceEpoch(rawTime.toInt() * 1000, isUtc: true),
      precipIntensity: _asDouble(json['precipIntensity']),
      precipProbability: _asDouble(json['precipProbability']),
      precipType: json['precipType'] as String?,
    );
  }
}

/// The subset of a Pirate Weather `/forecast` response this app parses.
class PirateWeatherResponse {
  const PirateWeatherResponse({required this.minutes, this.uvIndex});

  /// Chronological (Pirate Weather already returns them in order; not
  /// re-sorted here since a malformed/out-of-order response is itself
  /// meaningful "can't trust this" information the repository layer
  /// should see rather than silently paper over).
  final List<PirateWeatherMinuteEntry> minutes;

  /// `currently.uvIndex` — the same request already fetches this block
  /// (see `MinuteCastClient`, which no longer excludes `currently`), so
  /// UV Index rides along with the minutely fetch rather than requiring
  /// a second API call. Null if Pirate Weather didn't report one.
  final double? uvIndex;

  static PirateWeatherResponse? tryParse(Map<String, dynamic> json) {
    final minutely = json['minutely'];
    if (minutely is! Map) return null;
    final data = minutely['data'];
    if (data is! List) return null;

    final minutes = data
        .whereType<Map<String, dynamic>>()
        .map(PirateWeatherMinuteEntry.tryParse)
        .whereType<PirateWeatherMinuteEntry>()
        .toList();
    if (minutes.isEmpty) return null;

    final currently = json['currently'];
    final uvIndex = currently is Map ? _asDouble(currently['uvIndex']) : null;

    return PirateWeatherResponse(minutes: minutes, uvIndex: uvIndex);
  }
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return null;
}
