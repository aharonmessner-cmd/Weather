import 'package:equatable/equatable.dart';

import '../utils/unit_conversions.dart';
import 'nws/nws_observation.dart';
import 'weather_condition.dart';

/// A single point-in-time reading from a physical NWS observation station,
/// converted to US customary units. Backs the "Weather Details" section
/// (wind, humidity, dew point, visibility, pressure, precipitation).
class Observation extends Equatable {
  const Observation({
    this.observedAt,
    this.stationId,
    this.stationName,
    this.condition = WeatherCondition.unknown,
    this.conditionText,
    this.temperatureFahrenheit,
    this.dewPointFahrenheit,
    this.humidityPercent,
    this.windSpeedMph,
    this.windGustMph,
    this.windDirectionCompass,
    this.pressureInHg,
    this.visibilityMiles,
    this.heatIndexFahrenheit,
    this.windChillFahrenheit,
    this.precipitationLastHourInches,
  });

  final DateTime? observedAt;
  final String? stationId;
  final String? stationName;
  final WeatherCondition condition;
  final String? conditionText;
  final double? temperatureFahrenheit;
  final double? dewPointFahrenheit;
  final double? humidityPercent;
  final double? windSpeedMph;
  final double? windGustMph;
  final String? windDirectionCompass;
  final double? pressureInHg;
  final double? visibilityMiles;
  final double? heatIndexFahrenheit;
  final double? windChillFahrenheit;
  final double? precipitationLastHourInches;

  /// The best available "feels like" temperature: heat index in hot/humid
  /// conditions, wind chill in cold/windy ones, falling back to the actual
  /// temperature when neither applies.
  double? get feelsLikeFahrenheit =>
      heatIndexFahrenheit ?? windChillFahrenheit ?? temperatureFahrenheit;

  factory Observation.fromNws(
    NwsObservation raw, {
    String? stationId,
    String? stationName,
  }) {
    return Observation(
      observedAt: raw.timestamp,
      stationId: stationId,
      stationName: stationName,
      condition: WeatherCondition.fromNws(
        iconUrl: raw.icon,
        shortForecast: raw.textDescription,
      ),
      conditionText: raw.textDescription,
      temperatureFahrenheit: _c(raw.temperatureCelsius),
      dewPointFahrenheit: _c(raw.dewpointCelsius),
      humidityPercent: raw.relativeHumidityPercent,
      windSpeedMph: raw.windSpeedKmh == null ? null : kmhToMph(raw.windSpeedKmh!),
      windGustMph: raw.windGustKmh == null ? null : kmhToMph(raw.windGustKmh!),
      windDirectionCompass:
          raw.windDirectionDegrees == null ? null : degreesToCompass(raw.windDirectionDegrees!),
      pressureInHg: raw.barometricPressurePa == null ? null : paToInHg(raw.barometricPressurePa!),
      visibilityMiles: raw.visibilityMeters == null ? null : metersToMiles(raw.visibilityMeters!),
      heatIndexFahrenheit: _c(raw.heatIndexCelsius),
      windChillFahrenheit: _c(raw.windChillCelsius),
      precipitationLastHourInches:
          raw.precipitationLastHourMm == null ? null : mmToInches(raw.precipitationLastHourMm!),
    );
  }

  static double? _c(double? celsius) => celsius == null ? null : celsiusToFahrenheit(celsius);

  Map<String, dynamic> toJson() => {
        'observedAt': observedAt?.toIso8601String(),
        'stationId': stationId,
        'stationName': stationName,
        'condition': condition.name,
        'conditionText': conditionText,
        'temperatureFahrenheit': temperatureFahrenheit,
        'dewPointFahrenheit': dewPointFahrenheit,
        'humidityPercent': humidityPercent,
        'windSpeedMph': windSpeedMph,
        'windGustMph': windGustMph,
        'windDirectionCompass': windDirectionCompass,
        'pressureInHg': pressureInHg,
        'visibilityMiles': visibilityMiles,
        'heatIndexFahrenheit': heatIndexFahrenheit,
        'windChillFahrenheit': windChillFahrenheit,
        'precipitationLastHourInches': precipitationLastHourInches,
      };

  static Observation fromJson(Map<String, dynamic> json) => Observation(
        observedAt: DateTime.tryParse(json['observedAt'] as String? ?? ''),
        stationId: json['stationId'] as String?,
        stationName: json['stationName'] as String?,
        condition: WeatherCondition.values.firstWhere(
          (c) => c.name == json['condition'],
          orElse: () => WeatherCondition.unknown,
        ),
        conditionText: json['conditionText'] as String?,
        temperatureFahrenheit: (json['temperatureFahrenheit'] as num?)?.toDouble(),
        dewPointFahrenheit: (json['dewPointFahrenheit'] as num?)?.toDouble(),
        humidityPercent: (json['humidityPercent'] as num?)?.toDouble(),
        windSpeedMph: (json['windSpeedMph'] as num?)?.toDouble(),
        windGustMph: (json['windGustMph'] as num?)?.toDouble(),
        windDirectionCompass: json['windDirectionCompass'] as String?,
        pressureInHg: (json['pressureInHg'] as num?)?.toDouble(),
        visibilityMiles: (json['visibilityMiles'] as num?)?.toDouble(),
        heatIndexFahrenheit: (json['heatIndexFahrenheit'] as num?)?.toDouble(),
        windChillFahrenheit: (json['windChillFahrenheit'] as num?)?.toDouble(),
        precipitationLastHourInches: (json['precipitationLastHourInches'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [
        observedAt,
        stationId,
        temperatureFahrenheit,
        condition,
        windSpeedMph,
        humidityPercent,
      ];
}
