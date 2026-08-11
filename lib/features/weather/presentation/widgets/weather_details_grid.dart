import 'package:flutter/material.dart';

import '../../../../core/models/hourly_forecast.dart';
import '../../../../core/models/observation.dart';
import '../../../../core/utils/sun_times.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/glass_style.dart';
import 'info_metric_card.dart';
import 'precipitation_sparkline.dart';
import 'sunrise_arc_card.dart';
import 'wind_compass_card.dart';

/// The full weather-details layout: a wind compass and sunrise arc as the
/// two graphic "hero" cards — the arc fills the grid slot the Figma
/// reference gave to UV Index, using pure client-side astronomy instead of
/// adding an external UV API — a precipitation trend when there's a
/// non-zero chance in the visible hours, then small metric cards
/// (humidity, dew point, visibility, pressure, gusts, last-hour
/// precipitation) for everything else. Hidden entries (e.g. no gust data)
/// are simply omitted, since NWS stations frequently don't report every
/// field.
class WeatherDetailsGrid extends StatelessWidget {
  const WeatherDetailsGrid({
    super.key,
    required this.observation,
    required this.contentColor,
    required this.style,
    this.hourlyEntries = const [],
    this.sunTimes,
    this.now,
    this.timeZone,
  });

  final Observation? observation;
  final Color contentColor;
  final GlassStyle style;

  /// Backs [PrecipitationSparkline]; omitted (empty) hides that card.
  final List<HourlyForecastEntry> hourlyEntries;

  /// Backs [SunriseArcCard]; null hides that card (e.g. no coordinates
  /// available yet).
  final SunTimes? sunTimes;
  final DateTime? now;

  /// The location's IANA time zone, forwarded to [SunriseArcCard] and
  /// [PrecipitationSparkline] so their clock labels match the location,
  /// not the device.
  final String? timeZone;

  @override
  Widget build(BuildContext context) {
    final obs = observation;
    if (obs == null) {
      return Text(
        'No current observation available.',
        style: TextStyle(fontFamily: AppTypography.fontBody, color: contentColor.withValues(alpha: 0.62)),
      );
    }

    final metrics = <InfoMetricCard>[
      if (obs.windGustMph != null)
        InfoMetricCard(
          icon: Icons.storm_rounded,
          label: 'Gusts',
          value: '${obs.windGustMph!.round()} mph',
          contentColor: contentColor,
          style: style,
        ),
      InfoMetricCard(
        icon: Icons.water_drop_outlined,
        label: 'Humidity',
        value: obs.humidityPercent != null ? '${obs.humidityPercent!.round()}%' : '--',
        contentColor: contentColor,
        style: style,
      ),
      InfoMetricCard(
        icon: Icons.thermostat_outlined,
        label: 'Dew Point',
        value: obs.dewPointFahrenheit != null ? '${obs.dewPointFahrenheit!.round()}°' : '--',
        contentColor: contentColor,
        style: style,
      ),
      InfoMetricCard(
        icon: Icons.visibility_outlined,
        label: 'Visibility',
        value: obs.visibilityMiles != null ? '${obs.visibilityMiles!.toStringAsFixed(1)} mi' : '--',
        contentColor: contentColor,
        style: style,
      ),
      InfoMetricCard(
        icon: Icons.speed_outlined,
        label: 'Pressure',
        value: obs.pressureInHg != null ? '${obs.pressureInHg!.toStringAsFixed(2)} in' : '--',
        contentColor: contentColor,
        style: style,
      ),
      if (obs.precipitationLastHourInches != null)
        InfoMetricCard(
          icon: Icons.umbrella_outlined,
          label: 'Last Hour',
          value: '${obs.precipitationLastHourInches!.toStringAsFixed(2)} in',
          contentColor: contentColor,
          style: style,
        ),
    ];

    final times = sunTimes;
    final showPrecip = hourlyEntries.any((e) => (e.precipitationProbabilityPercent ?? 0) > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WindCompassCard(
                speedMph: obs.windSpeedMph,
                directionDegrees: obs.windDirectionDegrees,
                directionCompass: obs.windDirectionCompass,
                contentColor: contentColor,
                style: style,
              ),
            ),
            if (times != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: SunriseArcCard(
                  sunTimes: times,
                  now: now ?? DateTime.now(),
                  contentColor: contentColor,
                  style: style,
                  timeZone: timeZone,
                ),
              ),
            ],
          ],
        ),
        if (showPrecip) ...[
          const SizedBox(height: 12),
          PrecipitationSparkline(entries: hourlyEntries, contentColor: contentColor, style: style, timeZone: timeZone),
        ],
        if (metrics.isNotEmpty) ...[
          const SizedBox(height: 12),
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
