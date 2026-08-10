import 'package:flutter/material.dart';

/// The degree symbol, drawn as its own small element rather than typeset
/// as an ordinary Unicode "°" superscript character — a default superscript
/// sits at the font's built-in superscript baseline, which looks like an
/// afterthought next to type this stylized. This is a simple ring, sized
/// and positioned by the caller relative to the digits it accompanies.
class DegreeGlyph extends StatelessWidget {
  const DegreeGlyph({super.key, required this.size, required this.color, this.strokeWidth});

  final double size;
  final Color color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DegreeRingPainter(color: color, strokeWidth: strokeWidth ?? (size * 0.16).clamp(1.5, 6.0)),
      ),
    );
  }
}

class _DegreeRingPainter extends CustomPainter {
  _DegreeRingPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - strokeWidth) / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(covariant _DegreeRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
