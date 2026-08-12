/// A secondary weather metric the user can independently show or hide on
/// the Weather screen's details area (see `WeatherDetailsGrid` and
/// Settings' "Weather Details" section). A finite, extensible set —
/// adding a future metric is a single new case here plus wiring it into
/// `WeatherDetailsGrid`'s composition, not a scattered new boolean.
///
/// This is a *display preference* only — see
/// `app/weather_metric_preferences_controller.dart` for persistence, and
/// `WeatherDetailsGrid` for how a metric's preference is combined with
/// whether the current provider actually has data for it (the two are
/// deliberately kept independent; see that widget's module doc).
enum WeatherMetric {
  feelsLike,
  humidity,
  dewPoint,
  pressure,
  precipitation,
  wind,
  uvIndex,
  visibility,
  windGusts,
  lastHourPrecipitation;

  /// The exact label shown for this metric in Settings' "Weather Details"
  /// toggle list.
  String get settingsLabel => switch (this) {
        WeatherMetric.feelsLike => 'Feels Like',
        WeatherMetric.humidity => 'Humidity',
        WeatherMetric.dewPoint => 'Dew Point',
        WeatherMetric.pressure => 'Pressure',
        WeatherMetric.precipitation => 'Precipitation',
        WeatherMetric.wind => 'Wind',
        WeatherMetric.uvIndex => 'UV Index',
        WeatherMetric.visibility => 'Visibility',
        WeatherMetric.windGusts => 'Wind Gusts',
        WeatherMetric.lastHourPrecipitation => 'Last Hour Precipitation',
      };
}
