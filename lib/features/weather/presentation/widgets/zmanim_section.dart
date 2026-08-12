import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/zmanim_settings_controller.dart';
import '../../../../core/models/location.dart';
import '../../../../core/models/zmanim/zman.dart';
import '../../../../core/models/zmanim/zman_selection.dart';
import '../../../../core/utils/location_time.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/glass_style.dart';
import '../../../../widgets/glass_card.dart';
import '../../application/zmanim_controller.dart';

/// Today's remaining Zmanim, in one glass card at the very bottom of the
/// weather screen (see weather_screen.dart) — strictly today, strictly
/// what's still ahead. Renders nothing at all (no placeholder, no "no
/// more zmanim today" card) when: the "Show Zmanim" setting is off, the
/// location has no known time zone yet, the Zmanim service is
/// unavailable, or every configured zman for today has already passed.
///
/// Re-evaluates "which rows are still upcoming" locally on a low-frequency
/// timer as time passes — this never calls the network on its own; it
/// only nudges `ZmanimController.ensureFresh()`, which itself only
/// fetches when today's cached snapshot is actually missing (i.e. the
/// calendar date rolled over). No API calls are ever made while the
/// section is hidden (the timer's tick is a no-op in that case).
class ZmanimSection extends ConsumerStatefulWidget {
  const ZmanimSection({
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
  ConsumerState<ZmanimSection> createState() => _ZmanimSectionState();
}

class _ZmanimSectionState extends ConsumerState<ZmanimSection> {
  Timer? _timer;

  ZmanimQuery get _query => (location: widget.location, timeZone: widget.timeZone);

  @override
  void initState() {
    super.initState();
    // Local-only re-render tick so rows drop off as the day progresses
    // without needing any other part of the screen to rebuild. A minute
    // granularity is plenty since these are clock-time rows, not a
    // live-updating countdown.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!ref.read(showZmanimProvider) || widget.timeZone == null) return;
      ref.read(zmanimControllerProvider(_query).notifier).ensureFresh();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(showZmanimProvider)) return const SizedBox.shrink();

    final availability = ref.watch(zmanimControllerProvider(_query));

    return availability.when(
      data: (value) {
        if (value is! ZmanimAvailable) return const SizedBox.shrink();
        final remaining = remainingZmanim(value.zmanim, DateTime.now());
        if (remaining.isEmpty) return const SizedBox.shrink();

        return _Card(zmanim: remaining, timeZone: widget.timeZone, contentColor: widget.contentColor, style: widget.style);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.zmanim, required this.timeZone, required this.contentColor, required this.style});

  final List<Zman> zmanim;
  final String? timeZone;
  final Color contentColor;
  final GlassStyle style;

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
            'Zmanim',
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Calculation times are approximate.',
            style: TextStyle(fontFamily: AppTypography.fontBody, fontSize: 11, color: secondaryColor),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < zmanim.length; i++) ...[
            if (i > 0)
              Semantics(
                excludeSemantics: true,
                child: Divider(color: style.border, height: 17, thickness: 1),
              ),
            _ZmanRow(
              zman: zmanim[i],
              timeZone: timeZone,
              contentColor: contentColor,
              secondaryColor: secondaryColor,
              emphasized: i == 0,
            ),
          ],
        ],
      ),
    );
  }
}

class _ZmanRow extends StatelessWidget {
  const _ZmanRow({
    required this.zman,
    required this.timeZone,
    required this.contentColor,
    required this.secondaryColor,
    required this.emphasized,
  });

  final Zman zman;
  final String? timeZone;
  final Color contentColor;
  final Color secondaryColor;

  /// The next upcoming zman (the first row, since [zmanim] is already
  /// narrowed to "remaining" and kept in order) gets a very subtle nudge
  /// — a touch bolder, same size and color — rather than a highlight
  /// pill or background tint.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final timeLabel = formatClockTime(zman.time, timeZone);

    return Semantics(
      label: '${zman.displayName}, $timeLabel',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                zman.displayName,
                style: TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 14,
                  fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
                  color: contentColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // The name may wrap to more than one line (Expanded above), but
            // the time never should -- Flexible+FittedBox lets it shrink
            // to fit its share of the row instead of forcing an overflow,
            // the same escape hatch used for HourlyForecastList's cells
            // and the MinuteCast timeline's time labels.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  timeLabel,
                  style: TextStyle(
                    fontFamily: AppTypography.fontDisplay,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: contentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
