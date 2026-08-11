import 'package:equatable/equatable.dart';

import '../location.dart';
import 'minute_precipitation_forecast.dart';

enum MinuteCastSource {
  pirateWeather;

  String get attributionLabel => switch (this) {
        MinuteCastSource.pirateWeather => 'Pirate Weather',
      };
}

/// A short-term (~60 minute) precipitation nowcast for one [Location] —
/// entirely separate from [WeatherData]; NWS knows nothing about this and
/// this knows nothing about NWS. See `core/repositories/minutecast_repository.dart`
/// for how staleness/availability is decided; this model only holds data.
class MinuteCast extends Equatable {
  const MinuteCast({
    required this.generatedAt,
    required this.location,
    required this.minutes,
    required this.source,
  });

  /// When this snapshot was produced (fetch time) — the basis for
  /// [isStaleAsOf], the same convention as `WeatherData.fetchedAt`.
  final DateTime generatedAt;
  final Location location;

  /// Chronological, starting at/near [generatedAt]. Never fabricated —
  /// exactly what the provider returned, filtered/parsed but not
  /// interpolated or extended.
  final List<MinutePrecipitationForecast> minutes;
  final MinuteCastSource source;

  /// The last minute this snapshot actually describes — the true horizon,
  /// which may be less than 60 minutes if the provider returned fewer.
  DateTime? get validUntil => minutes.isEmpty ? null : minutes.last.time;

  bool isStaleAsOf(DateTime now, {Duration threshold = const Duration(minutes: 20)}) {
    return now.difference(generatedAt) > threshold;
  }

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'location': location.toJson(),
        'minutes': minutes.map((m) => m.toJson()).toList(),
        'source': source.name,
      };

  static MinuteCast? tryFromJson(Map<String, dynamic> json) {
    final generatedAt = DateTime.tryParse(json['generatedAt'] as String? ?? '');
    final locationJson = json['location'];
    if (generatedAt == null || locationJson is! Map<String, dynamic>) return null;
    final location = Location.tryFromJson(locationJson);
    if (location == null) return null;

    final minutesJson = json['minutes'];
    final minutes = (minutesJson is List ? minutesJson : const [])
        .whereType<Map<String, dynamic>>()
        .map(MinutePrecipitationForecast.tryFromJson)
        .whereType<MinutePrecipitationForecast>()
        .toList();

    return MinuteCast(
      generatedAt: generatedAt,
      location: location,
      minutes: minutes,
      source: MinuteCastSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => MinuteCastSource.pirateWeather,
      ),
    );
  }

  @override
  List<Object?> get props => [generatedAt, location, minutes, source];
}
