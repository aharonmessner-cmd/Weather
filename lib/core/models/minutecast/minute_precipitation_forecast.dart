import 'package:equatable/equatable.dart';

import 'minute_cast_thresholds.dart';
import 'pirate_weather_minutely.dart';

/// What kind of precipitation a minute is reporting. Deliberately limited
/// to what Pirate Weather actually distinguishes — it does not report
/// freezing rain or "mixed" as a distinct category, so this doesn't
/// invent one either.
enum PrecipitationType {
  none,
  rain,
  snow,
  sleet,
  unknown;

  static PrecipitationType fromPirateWeather(String? raw) {
    return switch (raw) {
      'rain' => PrecipitationType.rain,
      'snow' => PrecipitationType.snow,
      'sleet' => PrecipitationType.sleet,
      null => PrecipitationType.none,
      _ => PrecipitationType.unknown,
    };
  }
}

/// Coarse intensity band, derived from [MinuteCastThresholds] — the
/// numeric mm/h rate is never shown in the main UI, only this category.
enum PrecipitationIntensity {
  none,
  light,
  moderate,
  heavy;

  static PrecipitationIntensity classify(double? mmPerHour) {
    final rate = mmPerHour ?? 0;
    if (rate < MinuteCastThresholds.dryMmPerHour) return PrecipitationIntensity.none;
    if (rate < MinuteCastThresholds.lightMaxMmPerHour) return PrecipitationIntensity.light;
    if (rate < MinuteCastThresholds.moderateMaxMmPerHour) return PrecipitationIntensity.moderate;
    return PrecipitationIntensity.heavy;
  }
}

/// One minute of app-level precipitation nowcast data. The UI (and every
/// layer above the provider client) works only with this — never Pirate
/// Weather's raw field names.
class MinutePrecipitationForecast extends Equatable {
  const MinutePrecipitationForecast({
    required this.time,
    required this.type,
    this.probability,
    this.intensityMmPerHour,
  });

  /// UTC instant this minute describes.
  final DateTime time;
  final PrecipitationType type;

  /// 0.0-1.0, null if the provider didn't report one for this minute.
  final double? probability;

  /// Liquid-equivalent rate in mm/h, null if the provider didn't report
  /// one for this minute. Internal/derivation use only — never shown
  /// directly in the main UI (see [intensityCategory]).
  final double? intensityMmPerHour;

  PrecipitationIntensity get intensityCategory => PrecipitationIntensity.classify(intensityMmPerHour);

  /// Whether this minute clears the "meaningful precipitation" bar —
  /// the single threshold every starting/ending/dry determination is
  /// built from.
  bool get isMeaningfulPrecipitation => (intensityMmPerHour ?? 0) >= MinuteCastThresholds.dryMmPerHour;

  factory MinutePrecipitationForecast.fromPirateWeather(PirateWeatherMinuteEntry entry) {
    return MinutePrecipitationForecast(
      time: entry.time,
      type: PrecipitationType.fromPirateWeather(entry.precipType),
      probability: entry.precipProbability,
      intensityMmPerHour: entry.precipIntensity,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'type': type.name,
        'probability': probability,
        'intensityMmPerHour': intensityMmPerHour,
      };

  static MinutePrecipitationForecast? tryFromJson(Map<String, dynamic> json) {
    final time = DateTime.tryParse(json['time'] as String? ?? '');
    if (time == null) return null;
    return MinutePrecipitationForecast(
      time: time,
      type: PrecipitationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PrecipitationType.unknown,
      ),
      probability: (json['probability'] as num?)?.toDouble(),
      intensityMmPerHour: (json['intensityMmPerHour'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [time, type, probability, intensityMmPerHour];
}
