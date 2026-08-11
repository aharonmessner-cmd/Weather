import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/minutecast/minute_precipitation_forecast.dart';
import '../../../../core/utils/location_time.dart';
import '../../../../theme/app_typography.dart';

const _rainColor = Color(0xFF6FB8DD);
const _snowColor = Color(0xFFF3F7FF);

/// The ~60-minute precipitation timeline: a hand-drawn smooth "skyline" of
/// intensity over time (no charting package), a clear NOW marker, and 3-4
/// compact clock labels below it. Rain and snow are told apart by both
/// color (matching [WeatherGlyph]'s existing rain/snow palette) and, for
/// snow, a dotted texture — so the distinction doesn't rely on color alone.
///
/// Deliberately draws only what [minutes] actually contains: a run that's
/// already wet at the first minute is not tapered down to zero at the left
/// edge (that would claim a dry start that was never observed), and a run
/// still wet at the last minute is cut off flat at the right edge rather
/// than tapered to zero (that would claim an end the data doesn't show).
class MinuteCastTimeline extends StatelessWidget {
  const MinuteCastTimeline({
    super.key,
    required this.minutes,
    required this.now,
    required this.contentColor,
    this.timeZone,
    this.height = 64,
  });

  final List<MinutePrecipitationForecast> minutes;
  final DateTime now;
  final Color contentColor;
  final String? timeZone;
  final double height;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = contentColor.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Precipitation intensity over the next hour, graphic',
          excludeSemantics: true,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _MinuteCastTimelinePainter(
                minutes: minutes,
                now: now,
                contentColor: contentColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _TimeLabelsRow(minutes: minutes, timeZone: timeZone, color: secondaryColor),
      ],
    );
  }
}

class _TimeLabelsRow extends StatelessWidget {
  const _TimeLabelsRow({required this.minutes, required this.timeZone, required this.color});

  final List<MinutePrecipitationForecast> minutes;
  final String? timeZone;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (minutes.length < 2) return const SizedBox.shrink();

    // 4 evenly-spaced labels (not per-minute) -- the start, two interior
    // thirds, and the end of whatever span the data actually covers.
    final indices = {
      0,
      ((minutes.length - 1) / 3).round(),
      ((minutes.length - 1) * 2 / 3).round(),
      minutes.length - 1,
    }.toList()
      ..sort();

    final style = TextStyle(fontFamily: AppTypography.fontBody, fontSize: 11, color: color);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final i in indices)
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(formatClockTimeCompact(minutes[i].time, timeZone), style: style),
            ),
          ),
      ],
    );
  }
}

class _MinuteCastTimelinePainter extends CustomPainter {
  _MinuteCastTimelinePainter({required this.minutes, required this.now, required this.contentColor});

  final List<MinutePrecipitationForecast> minutes;
  final DateTime now;
  final Color contentColor;

  static const _visualCapMmPerHour = 10.0;
  static const _minVisibleHeight = 0.22;

  @override
  void paint(Canvas canvas, Size size) {
    if (minutes.length < 2) return;

    final start = minutes.first.time;
    final end = minutes.last.time;
    final totalMs = end.difference(start).inMilliseconds;
    if (totalMs <= 0) return;

    double xFor(DateTime time) {
      final fraction = time.difference(start).inMilliseconds / totalMs;
      return fraction.clamp(0.0, 1.0) * size.width;
    }

    const topInset = 4.0;
    const baselineInset = 2.0;
    final baselineY = size.height - baselineInset;
    final usableHeight = size.height - topInset - baselineInset;

    final baselinePaint = Paint()
      ..color = contentColor.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baselineY), Offset(size.width, baselineY), baselinePaint);

    for (final run in _buildRuns(minutes)) {
      _paintRun(canvas, run, minutes, xFor, baselineY, usableHeight);
    }

    _paintNowMarker(canvas, size, xFor, start, end, topInset, baselineY);
  }

  void _paintRun(
    Canvas canvas,
    _Run run,
    List<MinutePrecipitationForecast> minutes,
    double Function(DateTime) xFor,
    double baselineY,
    double usableHeight,
  ) {
    final points = <Offset>[
      if (run.start > 0) Offset(xFor(minutes[run.start - 1].time), baselineY),
      for (var k = run.start; k < run.end; k++)
        Offset(xFor(minutes[k].time), baselineY - _normalizedHeight(minutes[k]) * usableHeight),
      if (run.end < minutes.length) Offset(xFor(minutes[run.end].time), baselineY),
    ];
    if (points.length < 2) return;

    final color = run.type == PrecipitationType.snow ? _snowColor : _rainColor;

    final fillPath = Path()..moveTo(points.first.dx, baselineY);
    if (points.first.dy != baselineY) fillPath.lineTo(points.first.dx, points.first.dy);
    _addSmoothCurve(fillPath, points);
    fillPath.lineTo(points.last.dx, baselineY);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.5));

    final strokePath = Path()..moveTo(points.first.dx, points.first.dy);
    _addSmoothCurve(strokePath, points);
    canvas.drawPath(
      strokePath,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    if (run.type == PrecipitationType.snow) {
      _paintSnowTexture(canvas, points);
    }
  }

  void _paintSnowTexture(Canvas canvas, List<Offset> points) {
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    const spacing = 9.0;
    var nextX = points.first.dx;
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final segmentWidth = p1.dx - p0.dx;
      if (segmentWidth <= 0) continue;
      while (nextX <= p1.dx) {
        if (nextX >= p0.dx) {
          final t = (nextX - p0.dx) / segmentWidth;
          final y = p0.dy + (p1.dy - p0.dy) * t;
          canvas.drawCircle(Offset(nextX, y - 3), 1.3, dotPaint);
        }
        nextX += spacing;
      }
    }
  }

  void _paintNowMarker(
    Canvas canvas,
    Size size,
    double Function(DateTime) xFor,
    DateTime start,
    DateTime end,
    double topInset,
    double baselineY,
  ) {
    final clampedNow = now.isBefore(start) ? start : (now.isAfter(end) ? end : now);
    final x = xFor(clampedNow);
    final linePaint = Paint()
      ..color = contentColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(x, topInset), Offset(x, baselineY), linePaint);
    canvas.drawCircle(Offset(x, topInset), 2.6, Paint()..color = contentColor.withValues(alpha: 0.9));
  }

  double _normalizedHeight(MinutePrecipitationForecast minute) {
    final rate = minute.intensityMmPerHour ?? 0;
    if (rate <= 0) return 0;
    final normalized = (rate / _visualCapMmPerHour).clamp(0.0, 1.0);
    return normalized < _minVisibleHeight ? _minVisibleHeight : normalized;
  }

  @override
  bool shouldRepaint(covariant _MinuteCastTimelinePainter oldDelegate) {
    return !listEquals(oldDelegate.minutes, minutes) ||
        oldDelegate.now != now ||
        oldDelegate.contentColor != contentColor;
  }
}

/// A maximal run of consecutive [MinutePrecipitationForecast.isMeaningfulPrecipitation]
/// minutes, with [type] the dominant precipitation type across it -- one
/// color per run, rather than flickering minute to minute, keeps the
/// timeline calm even when the raw data alternates types briefly.
class _Run {
  const _Run(this.start, this.end, this.type);

  final int start;
  final int end;
  final PrecipitationType type;
}

List<_Run> _buildRuns(List<MinutePrecipitationForecast> minutes) {
  final runs = <_Run>[];
  var i = 0;
  while (i < minutes.length) {
    if (!minutes[i].isMeaningfulPrecipitation) {
      i++;
      continue;
    }
    var j = i;
    while (j < minutes.length && minutes[j].isMeaningfulPrecipitation) {
      j++;
    }
    runs.add(_Run(i, j, _dominantType(minutes, i, j)));
    i = j;
  }
  return runs;
}

PrecipitationType _dominantType(List<MinutePrecipitationForecast> minutes, int start, int end) {
  final counts = <PrecipitationType, int>{};
  for (var k = start; k < end; k++) {
    final type = minutes[k].type;
    if (type == PrecipitationType.none) continue;
    counts[type] = (counts[type] ?? 0) + 1;
  }
  if (counts.isEmpty) return PrecipitationType.rain;
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

/// Draws a smooth curve through [points] by quadratic-Beziering to the
/// midpoint of each consecutive pair -- a standard, dependency-free way to
/// turn a polyline into a gentle curve (no external charting package).
void _addSmoothCurve(Path path, List<Offset> points) {
  for (var i = 0; i < points.length - 1; i++) {
    final p0 = points[i];
    final p1 = points[i + 1];
    final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
    path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
  }
  if (points.isNotEmpty) path.lineTo(points.last.dx, points.last.dy);
}
