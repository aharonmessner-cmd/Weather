import 'package:equatable/equatable.dart';

/// One candidate location returned by a location-name search — never
/// persisted on its own. Selecting one turns it into a saved [Location] via
/// [LocationsController], the same way "Use My Location" and manual
/// coordinate entry do.
///
/// Deliberately narrow: just enough to show a clean, disambiguated choice
/// in a list and hand coordinates off to NWS afterward. It doesn't carry
/// the geocoding provider's raw response — the whole point is that the UI,
/// and everything downstream, never needs to know which provider produced
/// it.
class GeocodeResult extends Equatable {
  const GeocodeResult({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.subtitle,
  });

  final double latitude;
  final double longitude;

  /// The place's own name, e.g. `"Middletown"`.
  final String name;

  /// A short disambiguating line shown under [name], e.g.
  /// `"New York, United States"` — or, when another result in the same
  /// search shares [name] and state, `"Orange County, New York"`.
  final String subtitle;

  @override
  List<Object?> get props => [latitude, longitude, name, subtitle];
}
