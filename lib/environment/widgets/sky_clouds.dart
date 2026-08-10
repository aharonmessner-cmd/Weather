import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Clouds distributed subtly through the background — not a hero
/// illustration sitting on top of the UI. Count and spread are derived
/// from [coverageFraction] (continuous, from [SkyPalette.cloudCoverageFraction])
/// and the actual canvas size; [opacity] scales the whole layer.
///
/// Two depth bands (far/near) give a little parallax and shape variety
/// rather than every cloud reading as the same stamp at a different
/// scale: far clouds are larger, fainter, and drift slower; near clouds
/// are fewer, a touch more opaque, and drift slightly faster. Both bands
/// use a fixed seed for their base layout — [animationSeconds] is the
/// only thing that changes from one paint to the next, so the composition
/// itself never reshuffles, only drifts.
///
/// Drift is deliberately slow (each cloud takes several minutes to cross
/// the screen) and wraps seamlessly: a cloud's position is computed as
/// `time * speed` modulo the draw width, so there's never a pop when it
/// re-enters from the opposite edge.
class SkyClouds extends StatelessWidget {
  const SkyClouds({
    super.key,
    required this.coverageFraction,
    required this.opacity,
    this.animationSeconds = 0,
  });

  final double coverageFraction;
  final double opacity;

  /// Elapsed time driving the drift offset. A plain double rather than an
  /// [AnimationController] here — this widget stays a pure function of
  /// its inputs; whatever owns the clock (see `sky_background.dart`) only
  /// needs to change this value at a slow, throttled rate for the drift
  /// to read as continuous, since the motion itself is so slow.
  final double animationSeconds;

  @override
  Widget build(BuildContext context) {
    if (coverageFraction <= 0.03 || opacity <= 0.02) return const SizedBox.shrink();
    return CustomPaint(
      painter: _CloudPainter(
        coverageFraction: coverageFraction,
        opacity: opacity,
        animationSeconds: animationSeconds,
      ),
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

class _CloudDef {
  _CloudDef({
    required this.xFraction,
    required this.yFraction,
    required this.radiusFraction,
    required this.puffs,
  });

  final double xFraction;
  final double yFraction;
  final double radiusFraction;
  final List<_CloudPuff> puffs;
}

class _CloudBand {
  const _CloudBand({
    required this.seed,
    required this.opacityFactor,
    required this.blurSigma,
    required this.speedPxPerSecond,
    required this.countFactor,
    required this.minCount,
  });

  final int seed;
  final double opacityFactor;
  final double blurSigma;
  final double speedPxPerSecond;
  final double countFactor;
  final int minCount;
}

// Far band: larger, fainter, more blurred, drifts slowest — reads as
// background haze. Near band: fewer, slightly crisper/more opaque,
// drifts a little faster — a mild parallax cue without ever competing
// for attention.
const _farBand = _CloudBand(
  seed: 4242,
  opacityFactor: 0.55,
  blurSigma: 22,
  speedPxPerSecond: 0.9,
  countFactor: 0.65,
  minCount: 2,
);
const _nearBand = _CloudBand(
  seed: 8765,
  opacityFactor: 1.0,
  blurSigma: 14,
  speedPxPerSecond: 1.6,
  countFactor: 0.45,
  minCount: 1,
);

List<_CloudDef> _buildClouds(_CloudBand band, double coverageFraction) {
  final random = math.Random(band.seed);
  final count = math.max(band.minCount, (2 + coverageFraction * 7 * band.countFactor).round());
  final clouds = <_CloudDef>[];
  for (var c = 0; c < count; c++) {
    final puffCount = 3 + random.nextInt(3); // 3-5 puffs, varied per cloud
    final puffs = <_CloudPuff>[
      const _CloudPuff(0, 0, 1.0),
      for (var p = 1; p < puffCount; p++)
        _CloudPuff(
          (random.nextDouble() - 0.5) * 1.6,
          (random.nextDouble() - 0.5) * 0.5,
          0.55 + random.nextDouble() * 0.3,
        ),
    ];
    clouds.add(
      _CloudDef(
        xFraction: random.nextDouble(),
        yFraction: 0.08 + random.nextDouble() * 0.5,
        radiusFraction: 0.09 + random.nextDouble() * 0.08,
        puffs: puffs,
      ),
    );
  }
  return clouds;
}

class _CloudPainter extends CustomPainter {
  _CloudPainter({required this.coverageFraction, required this.opacity, required this.animationSeconds});

  final double coverageFraction;
  final double opacity;
  final double animationSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    _paintBand(canvas, size, _farBand);
    _paintBand(canvas, size, _nearBand);
  }

  void _paintBand(Canvas canvas, Size size, _CloudBand band) {
    final clouds = _buildClouds(band, coverageFraction);
    final margin = size.width * 0.18;
    final wrapWidth = size.width + margin * 2;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: (0.22 * opacity * band.opacityFactor).clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, band.blurSigma);

    for (final cloud in clouds) {
      final driftedX =
          (cloud.xFraction * wrapWidth + animationSeconds * band.speedPxPerSecond) % wrapWidth - margin;
      final centerY = size.height * cloud.yFraction;
      final baseRadius = size.width * cloud.radiusFraction;

      for (final puff in cloud.puffs) {
        canvas.drawCircle(
          Offset(driftedX + puff.dxFraction * baseRadius * 1.6, centerY + puff.dyFraction * baseRadius * 1.6),
          baseRadius * puff.scale,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) =>
      oldDelegate.coverageFraction != coverageFraction ||
      oldDelegate.opacity != opacity ||
      oldDelegate.animationSeconds != animationSeconds;
}
