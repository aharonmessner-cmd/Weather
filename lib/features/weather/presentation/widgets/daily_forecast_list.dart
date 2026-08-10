import 'package:flutter/material.dart';

import '../../../../core/models/daily_forecast.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/glass_style.dart';
import '../../../../widgets/glass_card.dart';
import 'weather_glyphs.dart';

/// The multi-day forecast: one row per day with condition, precipitation
/// chance, and a low/high range bar scaled against the whole visible
/// forecast, all on a single [GlassCard] sitting on the sky.
class DailyForecastList extends StatelessWidget {
  const DailyForecastList({
    super.key,
    required this.entries,
    required this.contentColor,
    required this.style,
  });

  final List<DailyForecastEntry> entries;
  final Color contentColor;
  final GlassStyle style;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = contentColor.withValues(alpha: 0.62);

    if (entries.isEmpty) {
      return GlassCard(
        style: style,
        child: Text(
          'No daily forecast available.',
          style: TextStyle(fontFamily: AppTypography.fontBody, color: secondaryColor),
        ),
      );
    }

    final highs = entries.map((e) => e.highFahrenheit).whereType<int>();
    final lows = entries.map((e) => e.lowFahrenheit).whereType<int>();
    final overallHigh = highs.isEmpty ? null : highs.reduce((a, b) => a > b ? a : b);
    final overallLow = lows.isEmpty ? null : lows.reduce((a, b) => a < b ? a : b);

    return GlassCard(
      style: style,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            _DailyRow(
              entry: entries[i],
              overallHigh: overallHigh,
              overallLow: overallLow,
              contentColor: contentColor,
            ),
            if (i != entries.length - 1)
              Divider(height: 22, color: contentColor.withValues(alpha: 0.12)),
          ],
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({
    required this.entry,
    required this.overallHigh,
    required this.overallLow,
    required this.contentColor,
  });

  final DailyForecastEntry entry;
  final int? overallHigh;
  final int? overallLow;
  final Color contentColor;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = contentColor.withValues(alpha: 0.62);
    final precip = entry.precipitationProbabilityPercent ?? 0;

    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            entry.dayName,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: AppTypography.fontBody, fontSize: 15, fontWeight: FontWeight.w500, color: contentColor),
          ),
        ),
        SizedBox(
          width: 38,
          child: precip > 0
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.water_drop_rounded, size: 11, color: secondaryColor),
                      const SizedBox(width: 2),
                      Text(
                        '$precip%',
                        style: TextStyle(fontFamily: AppTypography.fontBody, fontSize: 11, color: secondaryColor),
                      ),
                    ],
                  ),
                )
              : null,
        ),
        WeatherGlyph(condition: entry.condition, size: 24),
        const SizedBox(width: 14),
        SizedBox(
          width: 30,
          child: Text(
            entry.lowFahrenheit != null ? '${entry.lowFahrenheit}°' : '--',
            textAlign: TextAlign.end,
            style: TextStyle(fontFamily: AppTypography.fontDisplay, fontSize: 14, color: secondaryColor),
          ),
        ),
        Expanded(
          child: _RangeBar(
            low: entry.lowFahrenheit,
            high: entry.highFahrenheit,
            overallLow: overallLow,
            overallHigh: overallHigh,
            trackColor: contentColor.withValues(alpha: 0.14),
            fillColor: contentColor,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            entry.highFahrenheit != null ? '${entry.highFahrenheit}°' : '--',
            textAlign: TextAlign.end,
            style: TextStyle(fontFamily: AppTypography.fontDisplay, fontSize: 14, fontWeight: FontWeight.w600, color: contentColor),
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
    required this.trackColor,
    required this.fillColor,
  });

  final int? low;
  final int? high;
  final int? overallLow;
  final int? overallHigh;
  final Color trackColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    if (low == null || high == null || overallLow == null || overallHigh == null || overallHigh == overallLow) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(height: 4, decoration: BoxDecoration(color: trackColor, borderRadius: BorderRadius.circular(2))),
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
              Container(height: 4, decoration: BoxDecoration(color: trackColor, borderRadius: BorderRadius.circular(2))),
              Positioned(
                left: width * start,
                width: fillWidth,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [fillColor.withValues(alpha: 0.55), fillColor],
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
