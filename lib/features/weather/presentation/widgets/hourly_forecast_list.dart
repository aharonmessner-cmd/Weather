import 'package:flutter/material.dart';

import '../../../../core/models/hourly_forecast.dart';
import '../../../../widgets/weather_icon.dart';

/// The horizontal hour-by-hour timeline: time, icon, temperature, and
/// precipitation chance (when non-zero) for each of the next hours.
class HourlyForecastList extends StatelessWidget {
  const HourlyForecastList({super.key, required this.entries});

  final List<HourlyForecastEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Text('No hourly forecast available.', style: theme.textTheme.bodyMedium);
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
        itemBuilder: (context, index) => _HourColumn(entry: entries[index]),
      ),
    );
  }
}

class _HourColumn extends StatelessWidget {
  const _HourColumn({required this.entry});

  final HourlyForecastEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final precip = entry.precipitationProbabilityPercent ?? 0;

    return SizedBox(
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_formatHour(entry.time), style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          WeatherIcon(condition: entry.condition, size: 26),
          const SizedBox(height: 10),
          Text(
            entry.temperatureFahrenheit != null ? '${entry.temperatureFahrenheit}°' : '--',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(
            height: 16,
            child: precip > 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.water_drop_rounded, size: 11, color: theme.colorScheme.primary),
                      const SizedBox(width: 2),
                      Text(
                        '$precip%',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  )
                : null,
          ),
        ],
      ),
    );
  }

  static String _formatHour(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final suffix = time.hour < 12 ? 'AM' : 'PM';
    return '$hour$suffix';
  }
}
