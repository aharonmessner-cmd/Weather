import 'package:flutter/material.dart';

import '../../../../core/models/daily_forecast.dart';
import '../../../../widgets/weather_icon.dart';

/// The multi-day forecast: one row per day with condition, precipitation
/// chance, and a low/high range bar scaled against the whole visible
/// forecast (so at a glance you can see which days are hottest/coldest).
class DailyForecastList extends StatelessWidget {
  const DailyForecastList({super.key, required this.entries});

  final List<DailyForecastEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Text('No daily forecast available.', style: theme.textTheme.bodyMedium);
    }

    final highs = entries.map((e) => e.highFahrenheit).whereType<int>();
    final lows = entries.map((e) => e.lowFahrenheit).whereType<int>();
    final overallHigh = highs.isEmpty ? null : highs.reduce((a, b) => a > b ? a : b);
    final overallLow = lows.isEmpty ? null : lows.reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          _DailyRow(entry: entries[i], overallHigh: overallHigh, overallLow: overallLow),
          if (i != entries.length - 1) const Divider(height: 24),
        ],
      ],
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({required this.entry, required this.overallHigh, required this.overallLow});

  final DailyForecastEntry entry;
  final int? overallHigh;
  final int? overallLow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final precip = entry.precipitationProbabilityPercent ?? 0;

    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(entry.dayName, style: theme.textTheme.bodyLarge, overflow: TextOverflow.ellipsis),
        ),
        SizedBox(
          width: 38,
          child: precip > 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.water_drop_rounded, size: 12, color: theme.colorScheme.primary),
                    const SizedBox(width: 2),
                    Text(
                      '$precip%',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                )
              : null,
        ),
        WeatherIcon(condition: entry.condition, size: 24),
        const SizedBox(width: 14),
        SizedBox(
          width: 30,
          child: Text(
            entry.lowFahrenheit != null ? '${entry.lowFahrenheit}°' : '--',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: _RangeBar(
            low: entry.lowFahrenheit,
            high: entry.highFahrenheit,
            overallLow: overallLow,
            overallHigh: overallHigh,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            entry.highFahrenheit != null ? '${entry.highFahrenheit}°' : '--',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.low,
    required this.high,
    required this.overallLow,
    required this.overallHigh,
  });

  final int? low;
  final int? high;
  final int? overallLow;
  final int? overallHigh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final track = theme.colorScheme.surfaceContainerHighest;

    if (low == null || high == null || overallLow == null || overallHigh == null || overallHigh == overallLow) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(height: 4, decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(2))),
      );
    }

    final range = (overallHigh! - overallLow!).toDouble();
    final start = ((low! - overallLow!) / range).clamp(0.0, 1.0);
    final end = ((high! - overallLow!) / range).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final fillWidth = (width * (end - start)).clamp(4.0, width);
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(height: 4, decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(2))),
              Positioned(
                left: width * start,
                width: fillWidth,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.5),
                        theme.colorScheme.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
