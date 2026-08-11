import 'package:equatable/equatable.dart';

import 'current_conditions.dart';
import 'daily_forecast.dart';
import 'hourly_forecast.dart';
import 'location.dart';
import 'observation.dart';
import 'weather_alert.dart';

/// Everything the UI needs to render the weather dashboard for one
/// [Location], with no NWS-specific structure leaking through.
///
/// This is the single object screens ask the repository for; it is also
/// exactly what gets serialized to the local cache.
class WeatherData extends Equatable {
  const WeatherData({
    required this.location,
    required this.current,
    required this.fetchedAt,
    this.observation,
    this.hourly = const [],
    this.daily = const [],
    this.alerts = const [],
    this.timeZone,
  });

  final Location location;
  final CurrentConditions current;
  final Observation? observation;
  final List<HourlyForecastEntry> hourly;
  final List<DailyForecastEntry> daily;
  final List<WeatherAlert> alerts;

  /// The IANA time zone identifier for [location] (e.g.
  /// `"America/New_York"`), as reported by NWS's own point resolution.
  ///
  /// Null for cached data fetched before this field existed, or on the
  /// rare point where NWS doesn't report one — callers that display times
  /// should treat that as "fall back to the device's local time zone",
  /// never as an error. See `core/utils/location_time.dart` for the
  /// shared formatter every location-local time display should eventually
  /// route through.
  final String? timeZone;

  /// When this snapshot was fetched from NWS (not when it was read from
  /// cache) — the basis for "stale data" indicators in the UI.
  final DateTime fetchedAt;

  bool isStaleAsOf(DateTime now, {Duration threshold = const Duration(minutes: 30)}) {
    return now.difference(fetchedAt) > threshold;
  }

  WeatherData copyWith({
    Location? location,
    CurrentConditions? current,
    Observation? observation,
    List<HourlyForecastEntry>? hourly,
    List<DailyForecastEntry>? daily,
    List<WeatherAlert>? alerts,
    DateTime? fetchedAt,
    String? timeZone,
  }) {
    return WeatherData(
      location: location ?? this.location,
      current: current ?? this.current,
      observation: observation ?? this.observation,
      hourly: hourly ?? this.hourly,
      daily: daily ?? this.daily,
      alerts: alerts ?? this.alerts,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      timeZone: timeZone ?? this.timeZone,
    );
  }

  Map<String, dynamic> toJson() => {
        'location': location.toJson(),
        'current': current.toJson(),
        'observation': observation?.toJson(),
        'hourly': hourly.map((h) => h.toJson()).toList(),
        'daily': daily.map((d) => d.toJson()).toList(),
        'alerts': alerts.map((a) => a.toJson()).toList(),
        'fetchedAt': fetchedAt.toIso8601String(),
        'timeZone': timeZone,
      };

  static WeatherData? tryFromJson(Map<String, dynamic> json) {
    final locationJson = json['location'];
    final currentJson = json['current'];
    final fetchedAt = DateTime.tryParse(json['fetchedAt'] as String? ?? '');
    if (locationJson is! Map<String, dynamic> || currentJson is! Map<String, dynamic> || fetchedAt == null) {
      return null;
    }
    final location = Location.tryFromJson(locationJson);
    if (location == null) return null;

    final observationJson = json['observation'];

    return WeatherData(
      location: location,
      current: CurrentConditions.fromJson(currentJson),
      observation: observationJson is Map<String, dynamic> ? Observation.fromJson(observationJson) : null,
      hourly: ((json['hourly'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HourlyForecastEntry.tryFromJson)
          .whereType<HourlyForecastEntry>()
          .toList(),
      daily: ((json['daily'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DailyForecastEntry.tryFromJson)
          .whereType<DailyForecastEntry>()
          .toList(),
      alerts: ((json['alerts'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(WeatherAlert.tryFromJson)
          .whereType<WeatherAlert>()
          .toList(),
      fetchedAt: fetchedAt,
      timeZone: json['timeZone'] as String?,
    );
  }

  @override
  List<Object?> get props => [location, current, observation, hourly, daily, alerts, fetchedAt, timeZone];
}
