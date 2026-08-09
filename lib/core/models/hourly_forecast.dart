import 'package:equatable/equatable.dart';

import '../utils/unit_conversions.dart';
import 'nws/nws_forecast_period.dart';
import 'weather_condition.dart';

/// A single hour's forecast, as shown in the hourly timeline.
class HourlyForecastEntry extends Equatable {
  const HourlyForecastEntry({
    required this.time,
    this.temperatureFahrenheit,
    this.condition = WeatherCondition.unknown,
    this.conditionText,
    this.precipitationProbabilityPercent,
    this.windSpeedMph,
    this.windDirectionCompass,
  });

  final DateTime time;
  final int? temperatureFahrenheit;
  final WeatherCondition condition;
  final String? conditionText;
  final int? precipitationProbabilityPercent;
  final double? windSpeedMph;
  final String? windDirectionCompass;

  factory HourlyForecastEntry.fromNws(NwsForecastPeriod period) {
    return HourlyForecastEntry(
      time: period.startTime,
      temperatureFahrenheit: period.temperature,
      condition: WeatherCondition.fromNws(
        iconUrl: period.icon,
        shortForecast: period.shortForecast,
      ),
      conditionText: period.shortForecast,
      precipitationProbabilityPercent: period.probabilityOfPrecipitationPercent,
      windSpeedMph: parseLeadingWindSpeedMph(period.windSpeed),
      windDirectionCompass: period.windDirection,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'temperatureFahrenheit': temperatureFahrenheit,
        'condition': condition.name,
        'conditionText': conditionText,
        'precipitationProbabilityPercent': precipitationProbabilityPercent,
        'windSpeedMph': windSpeedMph,
        'windDirectionCompass': windDirectionCompass,
      };

  static HourlyForecastEntry? tryFromJson(Map<String, dynamic> json) {
    final time = DateTime.tryParse(json['time'] as String? ?? '');
    if (time == null) return null;
    return HourlyForecastEntry(
      time: time,
      temperatureFahrenheit: json['temperatureFahrenheit'] as int?,
      condition: WeatherCondition.values.firstWhere(
        (c) => c.name == json['condition'],
        orElse: () => WeatherCondition.unknown,
      ),
      conditionText: json['conditionText'] as String?,
      precipitationProbabilityPercent: json['precipitationProbabilityPercent'] as int?,
      windSpeedMph: (json['windSpeedMph'] as num?)?.toDouble(),
      windDirectionCompass: json['windDirectionCompass'] as String?,
    );
  }

  @override
  List<Object?> get props => [time, temperatureFahrenheit, condition, precipitationProbabilityPercent];
}
