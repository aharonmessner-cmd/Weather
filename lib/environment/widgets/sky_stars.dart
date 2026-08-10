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
/// reshuffle on every rebuild — only [opacity] and the twinkle phase
/// (driven by [animationSeconds]) change moment to moment.
///
/// Twinkle is a small, independent brightness wobble per star (different
/// period and phase each, so nothing pulses in sync) — deliberately
/// subtle: a star should only seem to shimmer if you're actually looking
/// at it, never flash or read as a screensaver.
class SkyStars extends StatelessWidget {
  const SkyStars({super.key, required this.opacity, this.animationSeconds = 0});

  final double opacity;
  final double animationSeconds;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.005) return const SizedBox.shrink();
    return CustomPaint(
      painter: _StarFieldPainter(opacity: opacity, animationSeconds: animationSeconds),
      size: Size.infinite,
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  _StarFieldPainter({required this.opacity, required this.animationSeconds});

  final double opacity;
  final double animationSeconds;

  static const int _seed = 1337;

  /// How much a star's brightness wobbles, as a fraction of its base
  /// opacity — kept small so twinkle reads as alive, not blinking.
  static const double _twinkleAmplitude = 0.16;

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

      // Independent period (3.5-6.5s) and phase per star — drawn from the
      // same seeded stream, so this stays deterministic without needing
      // separately-stored state.
      final period = 3.5 + random.nextDouble() * 3.0;
      final phase = random.nextDouble() * 2 * math.pi;
      final twinkle = 1 + _twinkleAmplitude * math.sin(2 * math.pi * animationSeconds / period + phase);

      paint.color = Colors.white.withValues(alpha: (tierOpacity * opacity * twinkle).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.animationSeconds != animationSeconds;
}
