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
        if (data == null) return const SizedBox.shrink();

        return _Card(
          minutes: data.minutes,
          now: DateTime.now(),
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
    required this.now,
    required this.timeZone,
    required this.contentColor,
    required this.style,
    required this.isStale,
  });

  final List<MinutePrecipitationForecast> minutes;
  final DateTime now;
  final String? timeZone;
  final Color contentColor;
  final GlassStyle style;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    if (minutes.isEmpty) return const SizedBox.shrink();

    final secondaryColor = contentColor.withValues(alpha: 0.62);
    final summary = summarizeMinuteCast(minutes, now, timeZone: timeZone);

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
