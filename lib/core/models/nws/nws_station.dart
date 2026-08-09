import '../../utils/nws_json.dart';

/// Raw parse of a single feature from `GET {observationStations}`.
class NwsStation {
  const NwsStation({
    required this.stationId,
    this.name,
    this.latitude,
    this.longitude,
  });

  final String stationId;
  final String? name;
  final double? latitude;
  final double? longitude;

  static NwsStation? tryParse(Map<String, dynamic> json) {
    final properties = json['properties'];
    if (properties is! Map<String, dynamic>) return null;

    final stationId = nwsAsString(properties['stationIdentifier']);
    if (stationId == null) return null;

    double? lat;
    double? lon;
    final geometry = json['geometry'];
    if (geometry is Map) {
      final coordinates = geometry['coordinates'];
      if (coordinates is List && coordinates.length >= 2) {
        lon = nwsAsDouble(coordinates[0]);
        lat = nwsAsDouble(coordinates[1]);
      }
    }

    return NwsStation(
      stationId: stationId,
      name: nwsAsString(properties['name']),
      latitude: lat,
      longitude: lon,
    );
  }
}

/// Raw parse of `GET {observationStations}`.
///
/// Per the NWS API contract, stations are returned ordered nearest-first,
/// so [stations].first is the best default pick for "current conditions".
class NwsStationsResponse {
  const NwsStationsResponse({required this.stations});

  final List<NwsStation> stations;

  static NwsStationsResponse tryParse(Map<String, dynamic> json) {
    final features = nwsAsMapList(json['features']);
    final stations = features.map(NwsStation.tryParse).whereType<NwsStation>().toList();
    return NwsStationsResponse(stations: stations);
  }
}
