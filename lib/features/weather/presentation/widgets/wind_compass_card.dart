import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../theme/app_typography.dart';
import '../../../../theme/glass_style.dart';
import '../../../../widgets/glass_card.dart';

/// A compass-needle visualization of wind direction/speed, drawn from
/// [Observation.windDirectionDegrees] — the reason that field was added to
/// the model. Falls back to a dash-only face (no needle) when the station
/// didn't report a direction.
class WindCompassCard extends StatelessWidget {
  const WindCompassCard({
    super.key,
    required this.speedMph,
    required this.directionDegrees,
    required this.directionCompass,
    required this.contentColor,
    required this.style,
    this.gustMph,
  });

  final double? speedMph;
  final double? directionDegrees;
  final String? directionCompass;
  final Color contentColor;
  final GlassStyle style;

  /// Gust speed, shown as a small extra line beneath the main reading when
  /// present — this is the Wind Gusts metric, kept inside the compass card
  /// rather than split into its own tile (see `WeatherMetric.windGusts`).
  final double? gustMph;

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
            'Wind',
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              width: 92,
              height: 92,
              child: CustomPaint(
                painter: _CompassPainter(
                  directionDegrees: directionDegrees,
                  faceColor: contentColor.withValues(alpha: 0.16),
                  tickColor: secondaryColor,
                  needleColor: contentColor,
                ),
                child: Center(
                  child: Text(
                    speedMph != null ? '${speedMph!.round()}' : '--',
                    style: TextStyle(
                      fontFamily: AppTypography.fontDisplay,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: contentColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              speedMph != null
                  ? '${directionCompass != null ? '$directionCompass ' : ''}mph'
                  : 'No data',
              style: TextStyle(
                fontFamily: AppTypography.fontBody,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: secondaryColor,
              ),
            ),
          ),
          if (gustMph != null) ...[
            const SizedBox(height: 2),
            Center(
              child: Text(
                'Gusts ${gustMph!.round()} mph',
                style: TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.directionDegrees,
    required this.faceColor,
    required this.tickColor,
    required this.needleColor,
  });

  final double? directionDegrees;
  final Color faceColor;
  final Color tickColor;
  final Color needleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;

    final facePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 1, facePaint);

    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final inner = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 6);
      canvas.drawLine(inner, outer, tickPaint);
    }

    final direction = directionDegrees;
    if (direction == null) return;

    // Meteorological convention: 0deg = wind from the north. The needle
    // points in the direction the wind is blowing *from*, so it's drawn
    // pointing toward that bearing (0deg = up, clockwise).
    final angle = _degToRad(direction) - math.pi / 2;
    final direction2d = Offset(math.cos(angle), math.sin(angle));
    // Both ends sit on the *same* side of center, toward the bearing —
    // a short mark near the rim, not a hand pivoting through the middle.
    // The speed label lives at center; a needle that crossed through it
    // would merge into the digits (same color, similar stroke weight).
    final tip = center + direction2d * (radius - 10);
    final tail = center + direction2d * (radius * 0.55);

    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tail, tip, needlePaint);

    final headLength = 9.0;
    final headAngle = 0.45;
    final left = tip +
        Offset(math.cos(angle + math.pi - headAngle), math.sin(angle + math.pi - headAngle)) * headLength;
    final right = tip +
        Offset(math.cos(angle + math.pi + headAngle), math.sin(angle + math.pi + headAngle)) * headLength;
    final headPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(headPath, Paint()..color = needleColor);
  }

  double _degToRad(double deg) => deg * math.pi / 180;

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.directionDegrees != directionDegrees ||
      oldDelegate.faceColor != faceColor ||
      oldDelegate.needleColor != needleColor;
}
