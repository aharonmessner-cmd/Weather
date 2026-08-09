import '../../utils/nws_json.dart';

/// Raw parse of `GET /stations/{id}/observations/latest`.
///
/// Unlike the forecast endpoints, observations are always reported in SI
/// units (Celsius, km/h, meters, Pascals) regardless of any `units` query
/// parameter — the application-level conversion layer is responsible for
/// presenting these in the user's preferred units.
class NwsObservation {
  const NwsObservation({
    this.timestamp,
    this.textDescription,
    this.icon,
    this.temperatureCelsius,
    this.dewpointCelsius,
    this.windDirectionDegrees,
    this.windSpeedKmh,
    this.windGustKmh,
    this.barometricPressurePa,
    this.visibilityMeters,
    this.relativeHumidityPercent,
    this.windChillCelsius,
    this.heatIndexCelsius,
    this.precipitationLastHourMm,
  });

  final DateTime? timestamp;
  final String? textDescription;
  final String? icon;

  final double? temperatureCelsius;
  final double? dewpointCelsius;
  final double? windDirectionDegrees;
  final double? windSpeedKmh;
  final double? windGustKmh;
  final double? barometricPressurePa;
  final double? visibilityMeters;
  final double? relativeHumidityPercent;
  final double? windChillCelsius;
  final double? heatIndexCelsius;
  final double? precipitationLastHourMm;

  static NwsObservation? tryParse(Map<String, dynamic> json) {
    final properties = json['properties'];
    if (properties is! Map<String, dynamic>) return null;

    return NwsObservation(
      timestamp: nwsAsDateTime(properties['timestamp']),
      textDescription: nwsAsString(properties['textDescription']),
      icon: nwsAsString(properties['icon']),
      temperatureCelsius: nwsQuantity(properties['temperature']),
      dewpointCelsius: nwsQuantity(properties['dewpoint']),
      windDirectionDegrees: nwsQuantity(properties['windDirection']),
      windSpeedKmh: nwsQuantity(properties['windSpeed']),
      windGustKmh: nwsQuantity(properties['windGust']),
      barometricPressurePa: nwsQuantity(properties['barometricPressure']),
      visibilityMeters: nwsQuantity(properties['visibility']),
      relativeHumidityPercent: nwsQuantity(properties['relativeHumidity']),
      windChillCelsius: nwsQuantity(properties['windChill']),
      heatIndexCelsius: nwsQuantity(properties['heatIndex']),
      precipitationLastHourMm: nwsQuantity(properties['precipitationLastHour']),
    );
  }
}
