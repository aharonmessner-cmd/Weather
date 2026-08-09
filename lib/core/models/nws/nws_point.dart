import '../../utils/nws_json.dart';

/// Raw parse of `GET /points/{lat},{lon}`.
///
/// This is the entry point into the NWS grid system: every other endpoint
/// we call (forecast, hourly forecast, observation stations) is reached via
/// a URL handed back here rather than one we construct ourselves.
class NwsPoint {
  const NwsPoint({
    required this.gridId,
    required this.gridX,
    required this.gridY,
    required this.forecastUrl,
    required this.forecastHourlyUrl,
    required this.observationStationsUrl,
    this.timeZone,
    this.relativeCityName,
    this.relativeCityState,
  });

  /// The NWS forecast office identifier, e.g. `"LWX"`.
  final String gridId;
  final int gridX;
  final int gridY;
  final String forecastUrl;
  final String forecastHourlyUrl;
  final String observationStationsUrl;
  final String? timeZone;
  final String? relativeCityName;
  final String? relativeCityState;

  static NwsPoint? tryParse(Map<String, dynamic> json) {
    final properties = json['properties'];
    if (properties is! Map<String, dynamic>) return null;

    final gridId = nwsAsString(properties['gridId']);
    final gridX = nwsAsInt(properties['gridX']);
    final gridY = nwsAsInt(properties['gridY']);
    final forecastUrl = nwsAsString(properties['forecast']);
    final forecastHourlyUrl = nwsAsString(properties['forecastHourly']);
    final observationStationsUrl = nwsAsString(properties['observationStations']);

    if (gridId == null ||
        gridX == null ||
        gridY == null ||
        forecastUrl == null ||
        forecastHourlyUrl == null ||
        observationStationsUrl == null) {
      return null;
    }

    final relativeLocation = properties['relativeLocation'];
    String? cityName;
    String? cityState;
    if (relativeLocation is Map) {
      final relProps = relativeLocation['properties'];
      if (relProps is Map) {
        cityName = nwsAsString(relProps['city']);
        cityState = nwsAsString(relProps['state']);
      }
    }

    return NwsPoint(
      gridId: gridId,
      gridX: gridX,
      gridY: gridY,
      forecastUrl: forecastUrl,
      forecastHourlyUrl: forecastHourlyUrl,
      observationStationsUrl: observationStationsUrl,
      timeZone: nwsAsString(properties['timeZone']),
      relativeCityName: cityName,
      relativeCityState: cityState,
    );
  }
}
