import '../../utils/nws_json.dart';

/// Raw parse of a single period from either the standard forecast
/// (`/forecast`, ~12h day/night periods) or the hourly forecast
/// (`/forecast/hourly`, 1h periods). NWS uses an identical period shape for
/// both endpoints.
class NwsForecastPeriod {
  const NwsForecastPeriod({
    required this.startTime,
    required this.endTime,
    this.name,
    this.isDaytime,
    this.temperature,
    this.temperatureUnit,
    this.probabilityOfPrecipitationPercent,
    this.dewpointCelsius,
    this.relativeHumidityPercent,
    this.windSpeed,
    this.windGust,
    this.windDirection,
    this.icon,
    this.shortForecast,
    this.detailedForecast,
  });

  final DateTime startTime;
  final DateTime endTime;

  /// Present on daily/multi-period forecasts (e.g. `"Tonight"`,
  /// `"Wednesday"`); absent on hourly forecasts.
  final String? name;
  final bool? isDaytime;

  /// Degrees, in [temperatureUnit] (usually Fahrenheit — NWS defaults to
  /// `units=us` for forecast endpoints).
  final int? temperature;
  final String? temperatureUnit;

  final int? probabilityOfPrecipitationPercent;
  final double? dewpointCelsius;
  final double? relativeHumidityPercent;

  /// Free-text wind description as NWS provides it, e.g. `"10 mph"` or
  /// `"10 to 15 mph"`. Not a clean numeric value — the application layer
  /// parses the leading number out of this for display/sorting.
  final String? windSpeed;
  final String? windGust;
  final String? windDirection;

  final String? icon;
  final String? shortForecast;
  final String? detailedForecast;

  static NwsForecastPeriod? tryParse(Map<String, dynamic> json) {
    final startTime = nwsAsDateTime(json['startTime']);
    final endTime = nwsAsDateTime(json['endTime']);
    if (startTime == null || endTime == null) return null;

    return NwsForecastPeriod(
      startTime: startTime,
      endTime: endTime,
      name: nwsAsString(json['name']),
      isDaytime: nwsAsBool(json['isDaytime']),
      temperature: nwsAsInt(json['temperature']),
      temperatureUnit: nwsAsString(json['temperatureUnit']),
      probabilityOfPrecipitationPercent: nwsQuantity(json['probabilityOfPrecipitation'])?.round(),
      dewpointCelsius: nwsQuantity(json['dewpoint']),
      relativeHumidityPercent: nwsQuantity(json['relativeHumidity']),
      windSpeed: nwsAsString(json['windSpeed']),
      windGust: nwsAsString(json['windGust']),
      windDirection: nwsAsString(json['windDirection']),
      icon: nwsAsString(json['icon']),
      shortForecast: nwsAsString(json['shortForecast']),
      detailedForecast: nwsAsString(json['detailedForecast']),
    );
  }
}

/// Raw parse of `/forecast` or `/forecast/hourly` — both endpoints share
/// this envelope shape, differing only in period granularity.
class NwsForecast {
  const NwsForecast({required this.periods, this.updated, this.generatedAt});

  final List<NwsForecastPeriod> periods;
  final DateTime? updated;
  final DateTime? generatedAt;

  static NwsForecast? tryParse(Map<String, dynamic> json) {
    final properties = json['properties'];
    if (properties is! Map<String, dynamic>) return null;

    final periodsJson = properties['periods'];
    if (periodsJson is! List) return null;

    final periods = periodsJson
        .whereType<Map<String, dynamic>>()
        .map(NwsForecastPeriod.tryParse)
        .whereType<NwsForecastPeriod>()
        .toList();

    return NwsForecast(
      periods: periods,
      updated: nwsAsDateTime(properties['updated']),
      generatedAt: nwsAsDateTime(properties['generatedAt']),
    );
  }
}
