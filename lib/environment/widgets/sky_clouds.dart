import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Clouds distributed subtly through the background — not a hero
/// illustration sitting on top of the UI. Count and spread are derived
/// from [coverageFraction] (continuous, from [SkyPalette.cloudCoverageFraction])
/// and the actual canvas size; [opacity] scales the whole layer.
///
/// Static in this stage (positions are deterministic, not animated) —
/// drift animation is Stage 7 (Advanced Atmospheric Polish); the
/// architecture here doesn't need to change to add it, since the drift
/// would just perturb these same generated positions over time.
class SkyClouds extends StatelessWidget {
  const SkyClouds({super.key, required this.coverageFraction, required this.opacity});

  final double coverageFraction;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (coverageFraction <= 0.03 || opacity <= 0.02) return const SizedBox.shrink();
    return CustomPaint(
      painter: _CloudPainter(coverageFraction: coverageFraction, opacity: opacity),
      size: Size.infinite,
    );
  }
}

class _CloudPuff {
  const _CloudPuff(this.dxFraction, this.dyFraction, this.scale);
  final double dxFraction;
  final double dyFraction;
  final double scale;
}

class _CloudPainter extends CustomPainter {
  _CloudPainter({required this.coverageFraction, required this.opacity});

  final double coverageFraction;
  final double opacity;

  static const int _seed = 4242;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final random = math.Random(_seed);
    final cloudCount = (2 + coverageFraction * 7).round();
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: (0.22 * opacity).clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    for (var c = 0; c < cloudCount; c++) {
      final centerX = random.nextDouble() * size.width;
      final centerY = size.height * (0.08 + random.nextDouble() * 0.5);
      final baseRadius = size.width * (0.09 + random.nextDouble() * 0.08);

      final puffs = [
        _CloudPuff(0, 0, 1.0),
        _CloudPuff(-0.7, 0.15, 0.7),
        _CloudPuff(0.65, 0.1, 0.75),
        _CloudPuff(0.15, -0.3, 0.6),
      ];
      for (final puff in puffs) {
        canvas.drawCircle(
          Offset(centerX + puff.dxFraction * baseRadius * 1.6, centerY + puff.dyFraction * baseRadius * 1.6),
          baseRadius * puff.scale,
          basePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) =>
      oldDelegate.coverageFraction != coverageFraction || oldDelegate.opacity != opacity;
}
