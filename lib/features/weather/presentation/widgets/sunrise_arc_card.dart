import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/location_time.dart';
import '../../../../core/utils/sun_times.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/glass_style.dart';
import '../../../../widgets/glass_card.dart';

/// Sunrise-to-sunset arc with the sun's current position along it, drawn
/// from [SunTimes] (pure client-side astronomy — see `sun_times.dart`, no
/// network call). This is the NWS-backed content filling the grid slot the
/// Figma reference gave to UV Index, which V1 deliberately doesn't add an
/// external API for.
class SunriseArcCard extends StatelessWidget {
  const SunriseArcCard({
    super.key,
    required this.sunTimes,
    required this.now,
    required this.contentColor,
    required this.style,
    this.timeZone,
  });

  final SunTimes sunTimes;
  final DateTime now;
  final Color contentColor;
  final GlassStyle style;

  /// The location's IANA time zone (e.g. `"America/New_York"`); null falls
  /// back to the device's local time zone.
  final String? timeZone;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = contentColor.withValues(alpha: 0.62);
    final sunrise = sunTimes.sunrise;
    final sunset = sunTimes.sunset;

    double? progress;
    if (sunrise != null && sunset != null && sunset.isAfter(sunrise)) {
      final total = sunset.difference(sunrise).inMilliseconds;
      final elapsed = now.difference(sunrise).inMilliseconds;
      progress = (elapsed / total).clamp(0.0, 1.0);
    }

    return GlassCard(
      style: style,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sun',
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: _progressLabel(progress),
            excludeSemantics: true,
            child: SizedBox(
              height: 46,
              width: double.infinity,
              child: CustomPaint(
                painter: _SunArcPainter(
                  progress: progress,
                  arcColor: contentColor.withValues(alpha: 0.28),
                  sunColor: contentColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TimeLabel(
                  label: 'Rise',
                  time: sunrise,
                  color: contentColor,
                  secondaryColor: secondaryColor,
                  timeZone: timeZone,
                ),
              ),
              Expanded(
                child: _TimeLabel(
                  label: 'Set',
                  time: sunset,
                  color: contentColor,
                  secondaryColor: secondaryColor,
                  alignEnd: true,
                  timeZone: timeZone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({
    required this.label,
    required this.time,
    required this.color,
    required this.secondaryColor,
    this.alignEnd = false,
    this.timeZone,
  });

  final String label;
  final DateTime? time;
  final Color color;
  final Color secondaryColor;
  final bool alignEnd;
  final String? timeZone;

  @override
  Widget build(BuildContext context) {
    final crossAlign = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: AppTypography.fontBody, fontSize: 11, color: secondaryColor),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            time != null ? formatClockTime(time!, timeZone) : '--',
            style: TextStyle(
              fontFamily: AppTypography.fontDisplay,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// The arc graphic's only accessible description — the sun's position
/// along it (how far through the day it is) has no other on-screen text
/// equivalent, unlike sunrise/sunset which are also spelled out below it.
String _progressLabel(double? progress) {
  if (progress == null) return 'Sun position unavailable';
  if (progress <= 0) return 'Before sunrise';
  if (progress >= 1) return 'After sunset';
  return '${(progress * 100).round()} percent of the way from sunrise to sunset';
}

const double sunArcHorizontalInset = 5.0;
const double sunArcEndpointRadius = 2.5;

/// The bounding rect of the sunrise-to-sunset dome for a given canvas
/// [size] -- a proper ellipse sized to exactly fill the available space
/// (not a fragment of some far larger, mostly-offscreen ellipse), so its
/// curvature stays smooth and proportionate at any card width. Exposed
/// (rather than kept private to the painter) so its geometry -- and
/// [sunArcPosition], which is defined purely in terms of it -- can be
/// tested directly without rendering.
Rect sunArcRect(Size size) {
  final baseline = size.height - sunArcEndpointRadius - 1;
  final arcHeight = baseline - 3;
  return Rect.fromLTWH(
    sunArcHorizontalInset,
    baseline - arcHeight * 2,
    size.width - sunArcHorizontalInset * 2,
    arcHeight * 2,
  );
}

/// The point on [rect]'s dome (its ellipse's top half) at day-progress
/// [progress] -- 0 is the sunrise endpoint, 0.5 is the peak (solar noon),
/// 1 is the sunset endpoint. This is the exact parametric point Flutter's
/// `Canvas.drawArc` itself walks along for the same rect/angle, so a sun
/// indicator placed here always sits precisely on the drawn line.
Offset sunArcPosition(Rect rect, double progress) {
  final angle = math.pi + progress * math.pi;
  return rect.center + Offset.fromDirection(angle, 1).scale(rect.width / 2, rect.height / 2);
}

/// A clean half-ellipse "dome" from sunrise to sunset with the sun's
/// current position on it -- see [sunArcRect]/[sunArcPosition] for the
/// geometry.
class _SunArcPainter extends CustomPainter {
  _SunArcPainter({required this.progress, required this.arcColor, required this.sunColor});

  /// 0-1 fraction of the way from sunrise to sunset, or null when either
  /// time is unavailable (e.g. polar day/night).
  final double? progress;
  final Color arcColor;
  final Color sunColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = sunArcRect(size);

    // The full sunrise-to-sunset dome, as a quiet reference track.
    final trackPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    final sunrisePoint = sunArcPosition(rect, 0);
    final sunsetPoint = sunArcPosition(rect, 1);
    final endpointPaint = Paint()..color = arcColor;
    canvas.drawCircle(sunrisePoint, sunArcEndpointRadius, endpointPaint);
    canvas.drawCircle(sunsetPoint, sunArcEndpointRadius, endpointPaint);

    final p = progress;
    if (p == null) return;

    // The portion of the dome already traveled, drawn brighter than the
    // quiet track so the current position reads as the visual focus.
    final traveledPaint = Paint()
      ..color = sunColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, p * math.pi, false, traveledPaint);

    final sunPosition = sunArcPosition(rect, p);

    // A soft, small glow behind the indicator rather than a harder shadow
    // or a second ring -- restrained, in keeping with the rest of the
    // app's glass system.
    canvas.drawCircle(
      sunPosition,
      8,
      Paint()
        ..color = sunColor.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(sunPosition, 4, Paint()..color = sunColor);
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.sunColor != sunColor || oldDelegate.arcColor != arcColor;
}
