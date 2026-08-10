import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  });

  final SunTimes sunTimes;
  final DateTime now;
  final Color contentColor;
  final GlassStyle style;

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
          SizedBox(
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TimeLabel(label: 'Rise', time: sunrise, color: contentColor, secondaryColor: secondaryColor),
              ),
              Expanded(
                child: _TimeLabel(
                  label: 'Set',
                  time: sunset,
                  color: contentColor,
                  secondaryColor: secondaryColor,
                  alignEnd: true,
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
  });

  final String label;
  final DateTime? time;
  final Color color;
  final Color secondaryColor;
  final bool alignEnd;

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
            time != null ? _formatTime(time!.toLocal()) : '--',
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

  static String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }
}

class _SunArcPainter extends CustomPainter {
  _SunArcPainter({required this.progress, required this.arcColor, required this.sunColor});

  /// 0-1 fraction of the way from sunrise to sunset, or null when either
  /// time is unavailable (e.g. polar day/night).
  final double? progress;
  final Color arcColor;
  final Color sunColor;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 4;
    final rect = Rect.fromLTWH(4, -size.height * 0.7, size.width - 8, size.height * 1.7);

    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, arcPaint);

    canvas.drawLine(Offset(4, baseline), Offset(size.width - 4, baseline), arcPaint..strokeWidth = 1);

    final p = progress;
    if (p == null) return;

    final angle = math.pi + p * math.pi;
    final center = rect.center;
    final radiusX = rect.width / 2;
    final radiusY = rect.height / 2;
    final sunPosition = Offset(
      center.dx + radiusX * math.cos(angle),
      center.dy + radiusY * math.sin(angle),
    );

    canvas.drawCircle(sunPosition, 5, Paint()..color = sunColor);
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.sunColor != sunColor;
}
