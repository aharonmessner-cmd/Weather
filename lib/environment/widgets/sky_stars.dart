import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A procedural star field — never a fixed collection of dots. Star count
/// and spread are derived from the actual canvas size, so a phone and a
/// desktop window each get a field that fits them rather than the same
/// literal set of coordinates stretched.
///
/// [opacity] is the single continuous knob: it comes straight from
/// [SkyPalette.starOpacity], which is itself a continuous function of
/// solar elevation (and cloud cover) — so stars fade in/out smoothly
/// across dusk/dawn rather than switching on at some fixed hour.
///
/// Positions are deterministic (fixed-seed `Random`) so the field doesn't
/// reshuffle on every rebuild — only [opacity] changes moment to moment.
class SkyStars extends StatelessWidget {
  const SkyStars({super.key, required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.005) return const SizedBox.shrink();
    return CustomPaint(
      painter: _StarFieldPainter(opacity: opacity),
      size: Size.infinite,
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  _StarFieldPainter({required this.opacity});

  final double opacity;

  static const int _seed = 1337;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final area = size.width * size.height;
    final starCount = (area / 3600).clamp(30, 240).round();
    final random = math.Random(_seed);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < starCount; i++) {
      final dx = random.nextDouble() * size.width;
      // Bias toward the upper ~75% of the sky — the lower band is where
      // horizon glow and cloud/precipitation layers dominate visually.
      final verticalBias = math.pow(random.nextDouble(), 1.4).toDouble();
      final dy = verticalBias * size.height * 0.75;

      final tier = random.nextDouble();
      final double radius;
      final double tierOpacity;
      if (tier < 0.7) {
        radius = 0.6;
        tierOpacity = 0.45;
      } else if (tier < 0.93) {
        radius = 1.1;
        tierOpacity = 0.7;
      } else {
        radius = 1.7;
        tierOpacity = 1.0;
      }

      paint.color = Colors.white.withValues(alpha: (tierOpacity * opacity).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => oldDelegate.opacity != opacity;
}
