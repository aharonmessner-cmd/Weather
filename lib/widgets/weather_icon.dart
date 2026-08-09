import 'package:flutter/material.dart';

import '../core/models/weather_condition.dart';

/// Renders a [WeatherCondition] as an icon.
///
/// Uses Material's built-in icon set rather than custom art for V1 — swap
/// the mapping below for illustrated/animated assets later without
/// touching any call site, since every screen renders conditions through
/// this widget instead of picking icons itself.
class WeatherIcon extends StatelessWidget {
  const WeatherIcon({
    super.key,
    required this.condition,
    this.isDaytime = true,
    this.size = 32,
    this.color,
  });

  final WeatherCondition condition;
  final bool isDaytime;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? _colorFor(condition, context);
    return Icon(_iconFor(condition, isDaytime), size: size, color: resolvedColor);
  }

  static IconData _iconFor(WeatherCondition condition, bool isDaytime) {
    switch (condition) {
      case WeatherCondition.clearSky:
        return isDaytime ? Icons.wb_sunny_rounded : Icons.nightlight_round;
      case WeatherCondition.mostlyClear:
        return isDaytime ? Icons.wb_twilight_rounded : Icons.nightlight_round;
      case WeatherCondition.partlyCloudy:
        return isDaytime ? Icons.wb_cloudy_rounded : Icons.cloud_rounded;
      case WeatherCondition.mostlyCloudy:
      case WeatherCondition.overcast:
        return Icons.cloud_rounded;
      case WeatherCondition.fog:
      case WeatherCondition.hazy:
      case WeatherCondition.smoke:
      case WeatherCondition.dust:
        return Icons.foggy;
      case WeatherCondition.drizzle:
        return Icons.grain_rounded;
      case WeatherCondition.rain:
      case WeatherCondition.rainShowers:
        return Icons.water_drop_rounded;
      case WeatherCondition.thunderstorms:
        return Icons.thunderstorm_rounded;
      case WeatherCondition.snow:
      case WeatherCondition.snowShowers:
        return Icons.ac_unit_rounded;
      case WeatherCondition.sleet:
      case WeatherCondition.freezingRain:
      case WeatherCondition.wintryMix:
        return Icons.severe_cold_rounded;
      case WeatherCondition.windy:
        return Icons.air_rounded;
      case WeatherCondition.tornado:
        return Icons.storm_rounded;
      case WeatherCondition.tropicalStorm:
      case WeatherCondition.hurricane:
        return Icons.cyclone_rounded;
      case WeatherCondition.hot:
        return Icons.thermostat_rounded;
      case WeatherCondition.cold:
        return Icons.ac_unit_rounded;
      case WeatherCondition.unknown:
        return Icons.help_outline_rounded;
    }
  }

  static Color _colorFor(WeatherCondition condition, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (condition) {
      case WeatherCondition.clearSky:
      case WeatherCondition.mostlyClear:
        return const Color(0xFFF5A623);
      case WeatherCondition.thunderstorms:
      case WeatherCondition.tornado:
      case WeatherCondition.tropicalStorm:
      case WeatherCondition.hurricane:
        return const Color(0xFF6B5CE7);
      case WeatherCondition.rain:
      case WeatherCondition.rainShowers:
      case WeatherCondition.drizzle:
        return const Color(0xFF3D7BFF);
      case WeatherCondition.snow:
      case WeatherCondition.snowShowers:
      case WeatherCondition.sleet:
      case WeatherCondition.freezingRain:
      case WeatherCondition.wintryMix:
      case WeatherCondition.cold:
        return const Color(0xFF7FC7E8);
      default:
        return scheme.onSurfaceVariant;
    }
  }
}
