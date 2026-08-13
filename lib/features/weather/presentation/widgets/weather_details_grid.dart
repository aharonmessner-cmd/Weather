import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/weather_metric_preferences_controller.dart';
import '../../../../core/models/allergy/allergy_level.dart';
import '../../../../core/models/hourly_forecast.dart';
import '../../../../core/models/location.dart';
import '../../../../core/models/observation.dart';
import '../../../../core/models/weather_metric.dart';
import '../../../../core/utils/sun_times.dart';
import '../../../../core/utils/uv_index.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/glass_style.dart';
import '../../application/allergy_controller.dart';
import '../../application/minute_cast_controller.dart';
import 'info_metric_card.dart';
import 'precipitation_sparkline.dart';
import 'sunrise_arc_card.dart';
import 'wind_compass_card.dart';

/// The full weather-details layout: a wind compass and sunrise arc as the
/// two graphic "hero" cards, a precipitation trend, then small metric
/// cards (humidity, dew point, visibility, pressure, UV Index, last-hour
/// precipitation, dust) for everything else. Wind gusts, when enabled and
/// available, show as a small extra line inside the wind compass card
/// itself rather than a separate tile — see [WindCompassCard.gustMph].
///
/// Two independent things decide whether a given piece shows up:
///   1. **Preference** — does the user want it on? Every [WeatherMetric]
///      is independently user-configurable; see Settings' "Weather
///      Details" section and [weatherMetricPreferencesProvider].
///   2. **Availability** — does the current data actually have a value
///      for it? (NWS stations frequently don't report every field; UV
///      Index comes from Pirate Weather/MinuteCast's existing fetch --
///      see [minuteCastControllerProvider]; Dust comes from a separate
///      Open-Meteo Air Quality fetch -- see [allergyControllerProvider].
///      Both are unavailable whenever their provider is, e.g. offline or
///      a malformed response -- never a fake/default value.)
///
/// A metric only renders when *both* are true. Nothing here ever shows a
/// placeholder for a disabled or unavailable metric — the grid simply has
/// fewer cells, which its existing wrap-style layout already reflows
/// around with no empty gaps.
class WeatherDetailsGrid extends ConsumerWidget {
  const WeatherDetailsGrid({
    super.key,
    required this.observation,
    required this.contentColor,
    required this.style,
    required this.location,
    this.hourlyEntries = const [],
    this.sunTimes,
    this.now,
    this.timeZone,
    this.feelsLikeFahrenheit,
  });

  final Observation? observation;
  final Color contentColor;
  final GlassStyle style;

  /// The currently selected location — needed to read UV Index from the
  /// same per-location MinuteCast/Pirate Weather data the MinuteCast
  /// section already fetches and caches.
  final Location location;

  /// Backs [PrecipitationSparkline]; empty (or the Precipitation
  /// preference being off) hides that card.
  final List<HourlyForecastEntry> hourlyEntries;

  /// Backs [SunriseArcCard]; null hides that card (e.g. no coordinates
  /// available yet).
  final SunTimes? sunTimes;
  final DateTime? now;

  /// The location's IANA time zone, forwarded to [SunriseArcCard] and
  /// [PrecipitationSparkline] so their clock labels match the location,
  /// not the device.
  final String? timeZone;

  /// From `CurrentConditions.feelsLikeFahrenheit` — passed in rather than
  /// a whole `CurrentConditions` object to keep this widget's dependency
  /// surface as narrow as the rest of its parameters.
  final double? feelsLikeFahrenheit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obs = observation;
    if (obs == null) {
      return Text(
        'No current observation available.',
        style: TextStyle(fontFamily: AppTypography.fontBody, color: contentColor.withValues(alpha: 0.62)),
      );
    }

    final enabled = ref.watch(weatherMetricPreferencesProvider);
    final uvIndex = _uvIndexFrom(ref.watch(minuteCastControllerProvider(location)).value);
    // Unlike MinuteCast (also fetched for the Precipitation sparkline
    // regardless of the UV preference), nothing else in this widget needs
    // Allergy data -- so it's only watched, and only ever fetched, when
    // the user actually has the preference on. This is what keeps
    // Allergies fully isolated: turning it off means literally no
    // request, not just a hidden card.
    final dustLevel = enabled.contains(WeatherMetric.allergies)
        ? _dustLevelFrom(ref.watch(allergyControllerProvider(location)).value)
        : null;

    final metrics = <InfoMetricCard>[
      if (enabled.contains(WeatherMetric.feelsLike) && feelsLikeFahrenheit != null)
        InfoMetricCard(
          icon: Icons.thermostat_rounded,
          label: 'Feels Like',
          value: '${feelsLikeFahrenheit!.round()}°',
          contentColor: contentColor,
          style: style,
        ),
      if (enabled.contains(WeatherMetric.humidity) && obs.humidityPercent != null)
        InfoMetricCard(
          icon: Icons.water_drop_outlined,
          label: 'Humidity',
          value: '${obs.humidityPercent!.round()}%',
          contentColor: contentColor,
          style: style,
        ),
      if (enabled.contains(WeatherMetric.dewPoint) && obs.dewPointFahrenheit != null)
        InfoMetricCard(
          icon: Icons.thermostat_outlined,
          label: 'Dew Point',
          value: '${obs.dewPointFahrenheit!.round()}°',
          contentColor: contentColor,
          style: style,
        ),
      if (enabled.contains(WeatherMetric.visibility) && obs.visibilityMiles != null)
        InfoMetricCard(
          icon: Icons.visibility_outlined,
          label: 'Visibility',
          value: '${obs.visibilityMiles!.toStringAsFixed(1)} mi',
          contentColor: contentColor,
          style: style,
        ),
      if (enabled.contains(WeatherMetric.pressure) && obs.pressureInHg != null)
        InfoMetricCard(
          icon: Icons.speed_outlined,
          label: 'Pressure',
          value: '${obs.pressureInHg!.toStringAsFixed(2)} in',
          contentColor: contentColor,
          style: style,
        ),
      if (enabled.contains(WeatherMetric.uvIndex) && uvIndex != null)
        InfoMetricCard(
          icon: Icons.wb_sunny_outlined,
          label: 'UV Index',
          value: '${roundUvIndex(uvIndex)}',
          caption: uvIndexCategory(roundUvIndex(uvIndex)),
          contentColor: contentColor,
          style: style,
        ),
      if (enabled.contains(WeatherMetric.lastHourPrecipitation) && obs.precipitationLastHourInches != null)
        InfoMetricCard(
          icon: Icons.umbrella_outlined,
          label: 'Last Hour',
          value: '${obs.precipitationLastHourInches!.toStringAsFixed(2)} in',
          contentColor: contentColor,
          style: style,
        ),
      if (enabled.contains(WeatherMetric.allergies) && dustLevel != null)
        InfoMetricCard(
          icon: Icons.grain_rounded,
          label: 'Dust',
          value: dustLevel.label,
          contentColor: contentColor,
          style: style,
        ),
    ];

    final times = sunTimes;
    final showPrecip = enabled.contains(WeatherMetric.precipitation) &&
        hourlyEntries.any((e) => (e.precipitationProbabilityPercent ?? 0) > 0);
    final showWind = enabled.contains(WeatherMetric.wind);

    final topRow = <Widget>[
      if (showWind)
        WindCompassCard(
          speedMph: obs.windSpeedMph,
          directionDegrees: obs.windDirectionDegrees,
          directionCompass: obs.windDirectionCompass,
          contentColor: contentColor,
          style: style,
          gustMph: enabled.contains(WeatherMetric.windGusts) ? obs.windGustMph : null,
        ),
      if (times != null)
        SunriseArcCard(
          sunTimes: times,
          now: now ?? DateTime.now(),
          contentColor: contentColor,
          style: style,
          timeZone: timeZone,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A disabled Wind preference (or no sunrise data yet) means the
        // row may end up with zero, one, or two cards -- reflow rather
        // than leaving an empty Expanded slot where the missing one was.
        if (topRow.length == 2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: topRow[0]),
              const SizedBox(width: 12),
              Expanded(child: topRow[1]),
            ],
          )
        else if (topRow.length == 1)
          topRow.single,
        if (showPrecip) ...[
          if (topRow.isNotEmpty) const SizedBox(height: 12),
          PrecipitationSparkline(entries: hourlyEntries, contentColor: contentColor, style: style, timeZone: timeZone),
        ],
        if (metrics.isNotEmpty) ...[
          if (topRow.isNotEmpty || showPrecip) const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 420 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.6,
                ),
                itemCount: metrics.length,
                itemBuilder: (context, index) => metrics[index],
              );
            },
          ),
        ],
      ],
    );
  }
}

double? _uvIndexFrom(MinuteCastAvailability? availability) {
  return switch (availability) {
    MinuteCastAvailable(:final data) => data.uvIndex,
    MinuteCastStale(:final data) => data.uvIndex,
    MinuteCastUnavailable() || null => null,
  };
}

AllergyLevel? _dustLevelFrom(AllergyAvailability? availability) {
  return switch (availability) {
    AllergyAvailable(:final data) => data.dustLevel,
    AllergyStale(:final data) => data.dustLevel,
    AllergyUnavailable() || null => null,
  };
}
