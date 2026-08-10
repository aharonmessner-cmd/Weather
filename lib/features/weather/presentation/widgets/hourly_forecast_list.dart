import 'package:flutter/material.dart';

import '../../../../core/models/hourly_forecast.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/glass_style.dart';
import '../../../../widgets/glass_card.dart';
import 'weather_glyphs.dart';

/// The horizontal hour-by-hour timeline: time, glyph, temperature, and
/// precipitation chance (when non-zero) for each of the next hours, on a
/// single [GlassCard] sitting on the sky.
class HourlyForecastList extends StatelessWidget {
  const HourlyForecastList({
    super.key,
    required this.entries,
    required this.contentColor,
    required this.style,
    this.isDaytime = true,
  });

  final List<HourlyForecastEntry> entries;
  final Color contentColor;
  final GlassStyle style;
  final bool isDaytime;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return GlassCard(
        style: style,
        child: Text(
          'No hourly forecast available.',
          style: TextStyle(fontFamily: AppTypography.fontBody, color: contentColor.withValues(alpha: 0.62)),
        ),
      );
    }

    return GlassCard(
      style: style,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: SizedBox(
        height: 116,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(width: 18),
          itemBuilder: (context, index) => _HourColumn(
            entry: entries[index],
            contentColor: contentColor,
            isDaytime: isDaytime,
          ),
        ),
      ),
    );
  }
}

class _HourColumn extends StatelessWidget {
  const _HourColumn({required this.entry, required this.contentColor, required this.isDaytime});

  final HourlyForecastEntry entry;
  final Color contentColor;
  final bool isDaytime;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = contentColor.withValues(alpha: 0.62);
    final precip = entry.precipitationProbabilityPercent ?? 0;

    return SizedBox(
      width: 46,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatHour(entry.time),
            style: TextStyle(fontFamily: AppTypography.fontBody, fontSize: 12, fontWeight: FontWeight.w500, color: secondaryColor),
          ),
          const SizedBox(height: 10),
          WeatherGlyph(condition: entry.condition, isDaytime: isDaytime, size: 24),
          const SizedBox(height: 10),
          Text(
            entry.temperatureFahrenheit != null ? '${entry.temperatureFahrenheit}°' : '--',
            style: TextStyle(fontFamily: AppTypography.fontDisplay, fontSize: 15, fontWeight: FontWeight.w600, color: contentColor),
          ),
          SizedBox(
            height: 16,
            child: precip > 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.water_drop_rounded, size: 10, color: secondaryColor),
                      const SizedBox(width: 2),
                      Text(
                        '$precip%',
                        style: TextStyle(fontFamily: AppTypography.fontBody, fontSize: 11, color: secondaryColor),
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
