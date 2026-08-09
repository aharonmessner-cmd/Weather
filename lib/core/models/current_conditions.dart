import 'package:equatable/equatable.dart';

import 'daily_forecast.dart';
import 'nws/nws_forecast_period.dart';
import 'observation.dart';
import 'weather_condition.dart';

/// The "right now" summary shown at the top of the weather dashboard.
///
/// Built by combining the freshest available station [Observation] (for
/// actual temperature/feels-like) with the current forecast period (as a
/// fallback when no observation is available) and today's high/low from the
/// daily forecast.
class CurrentConditions extends Equatable {
  const CurrentConditions({
    this.temperatureFahrenheit,
    this.feelsLikeFahrenheit,
    this.condition = WeatherCondition.unknown,
    this.conditionText,
    this.todayHighFahrenheit,
    this.todayLowFahrenheit,
    this.isDaytime,
  });

  final double? temperatureFahrenheit;
  final double? feelsLikeFahrenheit;
  final WeatherCondition condition;
  final String? conditionText;
  final int? todayHighFahrenheit;
  final int? todayLowFahrenheit;
  final bool? isDaytime;

  factory CurrentConditions.build({
    Observation? observation,
    NwsForecastPeriod? currentPeriod,
    DailyForecastEntry? today,
  }) {
    final temperature = observation?.temperatureFahrenheit ?? currentPeriod?.temperature?.toDouble();
    final hasObservationCondition =
        observation != null && observation.condition != WeatherCondition.unknown;

    return CurrentConditions(
      temperatureFahrenheit: temperature,
      feelsLikeFahrenheit: observation?.feelsLikeFahrenheit ?? temperature,
      condition: hasObservationCondition
          ? observation.condition
          : WeatherCondition.fromNws(
              iconUrl: currentPeriod?.icon,
              shortForecast: currentPeriod?.shortForecast,
            ),
      conditionText: observation?.conditionText ?? currentPeriod?.shortForecast,
      todayHighFahrenheit: today?.highFahrenheit,
      todayLowFahrenheit: today?.lowFahrenheit,
      isDaytime: currentPeriod?.isDaytime,
    );
  }

  Map<String, dynamic> toJson() => {
        'temperatureFahrenheit': temperatureFahrenheit,
        'feelsLikeFahrenheit': feelsLikeFahrenheit,
        'condition': condition.name,
        'conditionText': conditionText,
        'todayHighFahrenheit': todayHighFahrenheit,
        'todayLowFahrenheit': todayLowFahrenheit,
        'isDaytime': isDaytime,
      };

  static CurrentConditions fromJson(Map<String, dynamic> json) => CurrentConditions(
        temperatureFahrenheit: (json['temperatureFahrenheit'] as num?)?.toDouble(),
        feelsLikeFahrenheit: (json['feelsLikeFahrenheit'] as num?)?.toDouble(),
        condition: WeatherCondition.values.firstWhere(
          (c) => c.name == json['condition'],
          orElse: () => WeatherCondition.unknown,
        ),
        conditionText: json['conditionText'] as String?,
        todayHighFahrenheit: json['todayHighFahrenheit'] as int?,
        todayLowFahrenheit: json['todayLowFahrenheit'] as int?,
        isDaytime: json['isDaytime'] as bool?,
      );

  @override
  List<Object?> get props => [
        temperatureFahrenheit,
        feelsLikeFahrenheit,
        condition,
        todayHighFahrenheit,
        todayLowFahrenheit,
      ];
}
