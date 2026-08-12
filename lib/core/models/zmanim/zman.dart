import 'package:equatable/equatable.dart';

/// One resolved, displayable zman: a stable identity (from the
/// `ZmanDefinition` that produced it), the app's display name, and the
/// absolute instant it occurs. This is the *only* shape the Zmanim card
/// widget consumes — it never sees a [HebcalZmanField] or raw Hebcal JSON.
class Zman extends Equatable {
  const Zman({required this.id, required this.displayName, required this.time});

  final String id;
  final String displayName;

  /// Absolute UTC instant. Display-time conversion to the location's time
  /// zone happens only at presentation time (see `core/utils/location_time.dart`).
  final DateTime time;

  @override
  List<Object?> get props => [id, displayName, time];
}
