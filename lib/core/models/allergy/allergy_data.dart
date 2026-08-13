import 'package:equatable/equatable.dart';

import '../location.dart';
import 'allergy_level.dart';

enum AllergySource {
  openMeteo;

  String get attributionLabel => switch (this) {
        AllergySource.openMeteo => 'Open-Meteo',
      };
}

/// Current dust conditions for one [Location] -- entirely separate from
/// [WeatherData] and `MinuteCast`; NWS/Pirate Weather know nothing about
/// this and this knows nothing about them. See
/// `core/repositories/allergy_repository.dart` for how staleness/
/// availability is decided; this model only holds data.
///
/// Deliberately just dust -- there is no legitimate free data source for
/// pet/animal dander (see the module doc on `AllergyClient`), so this
/// never fabricates one.
class AllergyData extends Equatable {
  const AllergyData({
    required this.generatedAt,
    required this.location,
    required this.source,
    this.dustMicrogramsPerCubicMeter,
  });

  /// When this snapshot was produced (fetch time) -- the basis for
  /// [isStaleAsOf], the same convention as `WeatherData.fetchedAt`.
  final DateTime generatedAt;
  final Location location;
  final AllergySource source;

  /// Null if the provider didn't report a usable value for this point;
  /// callers must treat that as "unavailable," never a fake/default
  /// value.
  final double? dustMicrogramsPerCubicMeter;

  AllergyLevel? get dustLevel {
    final value = dustMicrogramsPerCubicMeter;
    return value == null ? null : dustLevelFromMicrogramsPerCubicMeter(value);
  }

  bool isStaleAsOf(DateTime now, {Duration threshold = const Duration(minutes: 20)}) {
    return now.difference(generatedAt) > threshold;
  }

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'location': location.toJson(),
        'source': source.name,
        'dustMicrogramsPerCubicMeter': dustMicrogramsPerCubicMeter,
      };

  static AllergyData? tryFromJson(Map<String, dynamic> json) {
    final generatedAt = DateTime.tryParse(json['generatedAt'] as String? ?? '');
    final locationJson = json['location'];
    if (generatedAt == null || locationJson is! Map<String, dynamic>) return null;
    final location = Location.tryFromJson(locationJson);
    if (location == null) return null;

    return AllergyData(
      generatedAt: generatedAt,
      location: location,
      source: AllergySource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => AllergySource.openMeteo,
      ),
      dustMicrogramsPerCubicMeter: (json['dustMicrogramsPerCubicMeter'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [generatedAt, location, source, dustMicrogramsPerCubicMeter];
}
