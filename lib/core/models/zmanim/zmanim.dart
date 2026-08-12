import 'package:equatable/equatable.dart';

import '../location.dart';
import 'hebcal_zman_field.dart';

/// A normalized, cacheable snapshot of everything Hebcal returned for one
/// location on one *location-local* calendar day — independent of any
/// user display configuration (see `ZmanimConfiguration` for that layer).
/// This is what `ZmanimRepository` fetches and caches; `selectZmanim` (in
/// `zman_selection.dart`) is what turns it, plus a configuration, into the
/// `List<Zman>` the card actually renders.
class Zmanim extends Equatable {
  const Zmanim({
    required this.locationDate,
    required this.location,
    required this.generatedAt,
    required this.times,
  });

  /// `YYYY-MM-DD` for the *location's* calendar date this snapshot
  /// describes — resolved via the location's IANA time zone, never the
  /// device's. The cache key and staleness check both key off this, not
  /// off [generatedAt], since a Zmanim snapshot is valid for exactly one
  /// calendar day regardless of when during that day it was fetched.
  final String locationDate;

  final Location location;

  /// When this snapshot was fetched — used only as a last-resort
  /// corruption backstop (see `ZmanimApiConfig.maxCacheAge`), not as the
  /// primary validity check (that's [locationDate]).
  final DateTime generatedAt;

  /// Every zman Hebcal returned for this day/location that this app
  /// recognizes. May be missing entries a particular configuration wants
  /// (e.g. an extreme-latitude day where a zman doesn't occur) — callers
  /// must handle a missing lookup, never assume completeness.
  final Map<HebcalZmanField, DateTime> times;

  Map<String, dynamic> toJson() => {
        'locationDate': locationDate,
        'location': location.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
        'times': times.map((field, time) => MapEntry(field.apiKey, time.toIso8601String())),
      };

  static Zmanim? tryFromJson(Map<String, dynamic> json) {
    final locationDate = json['locationDate'];
    final generatedAt = DateTime.tryParse(json['generatedAt'] as String? ?? '');
    final locationJson = json['location'];
    if (locationDate is! String || generatedAt == null || locationJson is! Map<String, dynamic>) return null;
    final location = Location.tryFromJson(locationJson);
    if (location == null) return null;

    final timesJson = json['times'];
    final times = <HebcalZmanField, DateTime>{};
    if (timesJson is Map) {
      for (final entry in timesJson.entries) {
        final field = HebcalZmanField.tryParse(entry.key as String?);
        final time = entry.value is String ? DateTime.tryParse(entry.value as String) : null;
        if (field != null && time != null) times[field] = time;
      }
    }
    if (times.isEmpty) return null;

    return Zmanim(locationDate: locationDate, location: location, generatedAt: generatedAt, times: times);
  }

  @override
  List<Object?> get props => [locationDate, location, generatedAt, times];
}
