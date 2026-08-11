import 'package:flutter/material.dart';

import '../../../../core/models/hourly_forecast.dart';
import '../../../../core/utils/location_time.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/glass_style.dart';
import '../../../../widgets/glass_card.dart';

/// A compact next-few-hours precipitation-chance trend: one bar per hour,
/// height scaled to probability. Reads directly from
/// [HourlyForecastEntry.precipitationProbabilityPercent] — no new data
/// source. Only shown when at least one of the visible hours has a
/// non-zero chance, so a dry stretch doesn't waste a card on a flat line.
class PrecipitationSparkline extends StatelessWidget {
  const PrecipitationSparkline({
    super.key,
    required this.entries,
    required this.contentColor,
    required this.style,
    this.hoursShown = 12,
    this.timeZone,
  });

  final List<HourlyForecastEntry> entries;
  final Color contentColor;
  final GlassStyle style;
  final int hoursShown;

  /// The location's IANA time zone (e.g. `"America/New_York"`); null falls
  /// back to the device's local time zone.
  final String? timeZone;

  bool get hasSignal => entries
      .take(hoursShown)
      .any((e) => (e.precipitationProbabilityPercent ?? 0) > 0);

  @override
  Widget build(BuildContext context) {
    final secondaryColor = contentColor.withValues(alpha: 0.62);
    final visible = entries.take(hoursShown).toList();

    return GlassCard(
      style: style,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Precipitation',
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in visible)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _Bar(
                        percent: entry.precipitationProbabilityPercent ?? 0,
                        color: contentColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (visible.isNotEmpty)
                Text(formatClockHour(visible.first.time, timeZone),
                    style: TextStyle(fontFamily: AppTypography.fontBody, fontSize: 11, color: secondaryColor)),
              if (visible.length > 1)
                Text(formatClockHour(visible.last.time, timeZone),
                    style: TextStyle(fontFamily: AppTypography.fontBody, fontSize: 11, color: secondaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.percent, required this.color});

  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final heightFraction = (percent / 100).clamp(0.04, 1.0);
    return FractionallySizedBox(
      heightFactor: heightFraction,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: percent > 0 ? 0.85 : 0.18),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
