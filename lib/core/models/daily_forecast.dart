import 'package:equatable/equatable.dart';

import 'nws/nws_forecast_period.dart';
import 'weather_condition.dart';

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// One calendar day's forecast summary, as shown in the multi-day list.
class DailyForecastEntry extends Equatable {
  const DailyForecastEntry({
    required this.date,
    required this.dayName,
    this.condition = WeatherCondition.unknown,
    this.conditionText,
    this.highFahrenheit,
    this.lowFahrenheit,
    this.precipitationProbabilityPercent,
    this.detailedForecast,
  });

  /// Midnight-normalized calendar date this entry describes.
  final DateTime date;

  /// NWS's own period label when available (`"Today"`, `"Tuesday"`),
  /// otherwise the plain weekday name.
  final String dayName;
  final WeatherCondition condition;
  final String? conditionText;
  final int? highFahrenheit;
  final int? lowFahrenheit;
  final int? precipitationProbabilityPercent;
  final String? detailedForecast;

  /// NWS's `/forecast` endpoint returns a flat list of alternating
  /// day/night periods (`"Today"`, `"Tonight"`, `"Tuesday"`,
  /// `"TuesdayNight"`, ...). This groups them by calendar date to produce
  /// one high/low entry per day.
  static List<DailyForecastEntry> fromNwsPeriods(List<NwsForecastPeriod> periods) {
    final byDate = <DateTime, List<NwsForecastPeriod>>{};
    for (final period in periods) {
      final date = DateTime(period.startTime.year, period.startTime.month, period.startTime.day);
      byDate.putIfAbsent(date, () => []).add(period);
    }

    final sortedDates = byDate.keys.toList()..sort();
    final entries = <DailyForecastEntry>[];

    for (final date in sortedDates) {
      final dayPeriods = byDate[date]!;
      final dayPeriod = _firstOrNull(dayPeriods.where((p) => p.isDaytime == true));
      final nightPeriod = _firstOrNull(dayPeriods.where((p) => p.isDaytime == false));
      final primary = dayPeriod ?? nightPeriod;
      if (primary == null) continue;

      entries.add(DailyForecastEntry(
        date: date,
        dayName: dayPeriod?.name ?? nightPeriod?.name ?? _weekdayNames[date.weekday - 1],
        condition: WeatherCondition.fromNws(iconUrl: primary.icon, shortForecast: primary.shortForecast),
        conditionText: primary.shortForecast,
        highFahrenheit: dayPeriod?.temperature,
        lowFahrenheit: nightPeriod?.temperature,
        precipitationProbabilityPercent: _maxProbability(dayPeriods),
        detailedForecast: primary.detailedForecast,
      ));
    }

    return entries;
  }

  static NwsForecastPeriod? _firstOrNull(Iterable<NwsForecastPeriod> periods) {
    for (final p in periods) {
      return p;
    }
    return null;
  }

  static int? _maxProbability(List<NwsForecastPeriod> periods) {
    int? max;
    for (final p in periods) {
      final prob = p.probabilityOfPrecipitationPercent;
      if (prob == null) continue;
      if (max == null || prob > max) max = prob;
    }
    return max;
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'dayName': dayName,
        'condition': condition.name,
        'conditionText': conditionText,
        'highFahrenheit': highFahrenheit,
        'lowFahrenheit': lowFahrenheit,
        'precipitationProbabilityPercent': precipitationProbabilityPercent,
        'detailedForecast': detailedForecast,
      };

  static DailyForecastEntry? tryFromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date'] as String? ?? '');
    final dayName = json['dayName'] as String?;
    if (date == null || dayName == null) return null;
    return DailyForecastEntry(
      date: date,
      dayName: dayName,
      condition: WeatherCondition.values.firstWhere(
        (c) => c.name == json['condition'],
        orElse: () => WeatherCondition.unknown,
      ),
      conditionText: json['conditionText'] as String?,
      highFahrenheit: json['highFahrenheit'] as int?,
      lowFahrenheit: json['lowFahrenheit'] as int?,
      precipitationProbabilityPercent: json['precipitationProbabilityPercent'] as int?,
      detailedForecast: json['detailedForecast'] as String?,
    );
  }

  @override
  List<Object?> get props => [date, dayName, condition, highFahrenheit, lowFahrenheit];
}
