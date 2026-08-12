import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The four top-level destinations' icons, hand-drawn as [CustomPainter]s
/// in the same spirit as `weather_glyphs.dart` — simple, flat, recognizable
/// shapes rather than Material Icons' glyphs, so the navigation reads as
/// part of this app's visual language instead of generic Android/Material
/// chrome.
///
/// Each glyph has a `selected` and unselected rendering: selected is drawn
/// bolder and fully opaque, unselected is a thinner, dimmer line-only
/// version — the same outline-vs-filled convention the rest of the app
/// already uses for its icon pairs, just custom-drawn instead of swapping
/// between two Material icon constants.
enum NavGlyphKind { weather, locations, alerts, settings }

class NavGlyph extends StatelessWidget {
  const NavGlyph({
    super.key,
    required this.kind,
    required this.color,
    this.selected = false,
    this.size = 24,
  });

  final NavGlyphKind kind;
  final Color color;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: switch (kind) {
          NavGlyphKind.weather => _SunGlyphPainter(color: color, selected: selected),
          NavGlyphKind.locations => _PinGlyphPainter(color: color, selected: selected),
          NavGlyphKind.alerts => _AlertGlyphPainter(color: color, selected: selected),
          NavGlyphKind.settings => _DialGlyphPainter(color: color, selected: selected),
        },
      ),
    );
  }
}

abstract class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.color, required this.selected});

  final Color color;
  final bool selected;

  double get strokeWidth => selected ? 1.8 : 1.4;

  Color get lineColor => selected ? color : color.withValues(alpha: 0.78);

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.selected != selected;
}

/// Weather: a sun — solid core always, rays that brighten/lengthen slightly
/// when selected rather than appearing from nothing, so the transition
/// feels like the sun "coming out" rather than an icon swap.
class _SunGlyphPainter extends _GlyphPainter {
  const _SunGlyphPainter({required super.color, required super.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final coreRadius = size.shortestSide * (selected ? 0.24 : 0.22);

    canvas.drawCircle(center, coreRadius, Paint()..color = lineColor);

    final rayPaint = Paint()
      ..color = lineColor.withValues(alpha: selected ? 0.95 : 0.6)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rayInner = coreRadius + size.shortestSide * 0.1;
    final rayOuter = rayInner + size.shortestSide * (selected ? 0.16 : 0.11);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(center + direction * rayInner, center + direction * rayOuter, rayPaint);
    }
  }
}

/// Locations: a map pin — teardrop outline with a small highlight dot in
/// place of a true cut-out hole (which would need to know the background
/// color to composite correctly against glass).
class _PinGlyphPainter extends _GlyphPainter {
  const _PinGlyphPainter({required super.color, required super.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final topCenter = Offset(w / 2, h * 0.16);
    final headRadius = w * 0.28;

    final path = Path()
      ..moveTo(topCenter.dx - headRadius, topCenter.dy)
      ..arcToPoint(
        Offset(topCenter.dx + headRadius, topCenter.dy),
        radius: Radius.circular(headRadius),
        clockwise: true,
      )
      ..quadraticBezierTo(topCenter.dx + headRadius, h * 0.55, w / 2, h * 0.92)
      ..quadraticBezierTo(topCenter.dx - headRadius, h * 0.55, topCenter.dx - headRadius, topCenter.dy)
      ..close();

    if (selected) {
      canvas.drawPath(path, Paint()..color = lineColor.withValues(alpha: 0.22));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(topCenter, headRadius * 0.34, Paint()..color = lineColor);
  }
}

/// Alerts: a rounded triangle with an exclamation mark — kept simple
/// enough to read at small sizes, unlike a literal storm/lightning
/// illustration would.
class _AlertGlyphPainter extends _GlyphPainter {
  const _AlertGlyphPainter({required super.color, required super.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final top = Offset(w / 2, h * 0.1);
    final left = Offset(w * 0.08, h * 0.88);
    final right = Offset(w * 0.92, h * 0.88);
    const corner = 0.16;

    Offset lerp(Offset a, Offset b, double t) => Offset.lerp(a, b, t)!;

    final path = Path()
      ..moveTo(lerp(top, left, corner).dx, lerp(top, left, corner).dy)
      ..lineTo(lerp(left, top, corner).dx, lerp(left, top, corner).dy)
      ..quadraticBezierTo(left.dx, left.dy, lerp(left, right, corner).dx, lerp(left, right, corner).dy)
      ..lineTo(lerp(right, left, corner).dx, lerp(right, left, corner).dy)
      ..quadraticBezierTo(right.dx, right.dy, lerp(right, top, corner).dx, lerp(right, top, corner).dy)
      ..lineTo(lerp(top, right, corner).dx, lerp(top, right, corner).dy)
      ..quadraticBezierTo(top.dx, top.dy, lerp(top, left, corner).dx, lerp(top, left, corner).dy)
      ..close();

    if (selected) {
      canvas.drawPath(path, Paint()..color = lineColor.withValues(alpha: 0.22));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round,
    );

    final markPaint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth * 1.15
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w / 2, h * 0.44), Offset(w / 2, h * 0.66), markPaint);
    canvas.drawCircle(Offset(w / 2, h * 0.76), strokeWidth * 0.65, Paint()..color = lineColor);
  }
}

/// Settings: three instrument-style sliders (an equalizer/mixing-console
/// motif) rather than a gear — fits the "premium weather instrument" feel
/// better than the literal-machinery connotation a gear carries.
class _DialGlyphPainter extends _GlyphPainter {
  const _DialGlyphPainter({required super.color, required super.selected});

  static const _knobPositions = [0.32, 0.62, 0.44];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final trackPaint = Paint()
      ..color = lineColor.withValues(alpha: selected ? 0.9 : 0.6)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final knobPaint = Paint()..color = lineColor;

    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.2 + i * 0.3);
      canvas.drawLine(Offset(w * 0.1, y), Offset(w * 0.9, y), trackPaint);
      final knobX = w * (0.1 + _knobPositions[i] * 0.8);
      canvas.drawCircle(Offset(knobX, y), selected ? 3.0 : 2.5, knobPaint);
    }
  }
}
