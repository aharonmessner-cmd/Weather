import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/location.dart';
import '../../../../core/models/minutecast/minute_cast_summary.dart';
import '../../../../core/models/minutecast/minute_precipitation_forecast.dart';
import '../../../../core/services/minutecast/minutecast_config.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/glass_style.dart';
import '../../../../widgets/glass_card.dart';
import '../../application/minute_cast_controller.dart';
import 'minutecast_timeline_painter.dart';

/// The MinuteCast card: natural-language headline/subtitle plus the
/// precipitation timeline, sitting directly above the hourly forecast (see
/// weather_screen.dart). Drives its own [minuteCastControllerProvider]
/// instance for [location] and nudges it on a ~5-minute timer while
/// mounted -- no background polling, matching the caching policy in
/// `minute_cast_controller.dart`.
///
/// Never shows an error state: [MinuteCastUnavailable] (for any reason)
/// and any unexpected [AsyncError] both render nothing, so a MinuteCast
/// failure can never turn the weather screen into an error screen.
///
/// Also renders nothing when [summarizeMinuteCast] finds no meaningful
/// precipitation at or after "now" within the data's own window (i.e.
/// [MinuteCastState.dry]) — MinuteCast is specifically a "what's
/// happening / about to happen right now" feature, not a general
/// forecast card, so a dry next hour means the section simply doesn't
/// exist on screen (no "no rain expected" placeholder).
class MinuteCastSection extends ConsumerStatefulWidget {
  const MinuteCastSection({
    super.key,
    required this.location,
    required this.contentColor,
    required this.style,
    this.timeZone,
  });

  final Location location;
  final Color contentColor;
  final GlassStyle style;
  final String? timeZone;

  @override
  ConsumerState<MinuteCastSection> createState() => _MinuteCastSectionState();
}

class _MinuteCastSectionState extends ConsumerState<MinuteCastSection> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(MinuteCastConfig.refreshInterval, (_) {
      ref.read(minuteCastControllerProvider(widget.location).notifier).ensureFresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availability = ref.watch(minuteCastControllerProvider(widget.location));

    return availability.when(
      data: (value) {
        final data = switch (value) {
          MinuteCastAvailable(:final data) => data,
          MinuteCastStale(:final data) => data,
          MinuteCastUnavailable() => null,
        };
        if (data == null || data.minutes.isEmpty) return const SizedBox.shrink();

        final now = DateTime.now();
        final summary = summarizeMinuteCast(data.minutes, now, timeZone: widget.timeZone);
        // No precipitation crossing the threshold anywhere in the data's
        // upcoming window -- MinuteCast is a "happening now / about to
        // happen" feature, not a general forecast, so it simply isn't on
        // screen for a dry hour.
        if (summary.state == MinuteCastState.dry) return const SizedBox.shrink();

        return _Card(
          minutes: data.minutes,
          summary: summary,
          now: now,
          timeZone: widget.timeZone,
          contentColor: widget.contentColor,
          style: widget.style,
          isStale: value is MinuteCastStale,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.minutes,
    required this.summary,
    required this.now,
    required this.timeZone,
    required this.contentColor,
    required this.style,
    required this.isStale,
  });

  final List<MinutePrecipitationForecast> minutes;
  final MinuteCastSummary summary;
  final DateTime now;
  final String? timeZone;
  final Color contentColor;
  final GlassStyle style;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = contentColor.withValues(alpha: 0.62);

    return GlassCard(
      style: style,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isStale ? 'Precipitation · Updating' : 'Precipitation',
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary.headline,
            style: TextStyle(
              fontFamily: AppTypography.fontDisplay,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: contentColor,
            ),
          ),
          if (summary.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              summary.subtitle!,
              style: TextStyle(fontFamily: AppTypography.fontBody, fontSize: 12.5, color: secondaryColor),
            ),
          ],
          const SizedBox(height: 14),
          MinuteCastTimeline(minutes: minutes, now: now, timeZone: timeZone, contentColor: contentColor),
        ],
      ),
    );
  }
}
