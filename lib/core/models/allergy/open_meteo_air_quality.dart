/// Raw parse of Open-Meteo's Air Quality `/v1/air-quality` response,
/// scoped to the single `current.dust` field this app actually uses.
/// Mirrors the shape of `core/models/minutecast/pirate_weather_minutely.dart`
/// — this is the *only* place that knows Open-Meteo's field names;
/// everything past this layer talks in [AllergyLevel]/`AllergyData`.
class OpenMeteoAirQualityResponse {
  const OpenMeteoAirQualityResponse({this.dustMicrogramsPerCubicMeter});

  /// Surface dust (desert/mineral aerosol) concentration in µg/m³, from
  /// the `current.dust` field. Null if Open-Meteo didn't report one for
  /// this point (e.g. outside model coverage).
  final double? dustMicrogramsPerCubicMeter;

  static OpenMeteoAirQualityResponse? tryParse(Map<String, dynamic> json) {
    final current = json['current'];
    if (current is! Map) return null;
    return OpenMeteoAirQualityResponse(dustMicrogramsPerCubicMeter: _asDouble(current['dust']));
  }
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return null;
}
