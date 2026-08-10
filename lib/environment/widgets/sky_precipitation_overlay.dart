import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../sky_palette.dart';

/// A subtle atmospheric suggestion of precipitation: a soft directional
/// veil plus a small number of slow-moving particles (thin rain streaks
/// or soft snow dots, per [kind]) and, for storms, an occasional gentle
/// brightening rather than a lightning-bolt graphic. None of this is meant
/// to be the focal point — it should read as "yes, it's raining/snowing/
/// stormy" at a glance, not draw the eye away from the temperature.
///
/// Particle counts are deliberately small (rain: 8-14 streaks, snow: 10-16
/// flakes) and everything moves slowly. Positions are seeded and
/// deterministic; only [animationSeconds] drives motion, at whatever
/// (low) rate the owner chooses to update it.
class SkyPrecipitationOverlay extends StatelessWidget {
  const SkyPrecipitationOverlay({
    super.key,
    required this.intensity,
    this.kind = SkyPrecipitationKind.none,
    this.stormFlicker = false,
    this.animationSeconds = 0,
  });

  final double intensity;
  final SkyPrecipitationKind kind;
  final bool stormFlicker;
  final double animationSeconds;

  @override
  Widget build(BuildContext context) {
    if (intensity <= 0.03 && !stormFlicker) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _PrecipitationPainter(
          intensity: intensity,
          kind: kind,
          stormFlicker: stormFlicker,
          animationSeconds: animationSeconds,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _PrecipitationPainter extends CustomPainter {
  _PrecipitationPainter({
    required this.intensity,
    required this.kind,
    required this.stormFlicker,
    required this.animationSeconds,
  });

  final double intensity;
  final SkyPrecipitationKind kind;
  final bool stormFlicker;
  final double animationSeconds;

  static const int _rainSeed = 5151;
  static const int _snowSeed = 9191;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.clipRect(Offset.zero & size);

    if (intensity > 0.03) {
      _paintVeil(canvas, size);
      switch (kind) {
        case SkyPrecipitationKind.rain:
          _paintRain(canvas, size);
        case SkyPrecipitationKind.snow:
          _paintSnow(canvas, size);
        case SkyPrecipitationKind.none:
          break;
      }
    }

    if (stormFlicker) _paintStormFlicker(canvas, size);
  }

  void _paintVeil(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Color.lerp(Colors.transparent, const Color(0xFF3A4A66), intensity * 0.35)!,
        ],
        stops: const [0.4, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintRain(Canvas canvas, Size size) {
    final random = math.Random(_rainSeed);
    final streakCount = (8 + intensity * 6).round().clamp(8, 14);
    final margin = size.height * 0.08;
    final wrapHeight = size.height + margin * 2;
    // Roughly one screen-height fall every 5-8 seconds — a slow, quiet
    // drift, never a driving-rain sense of speed.
    final paint = Paint()
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFBFD9EC).withValues(alpha: (0.28 * intensity).clamp(0.0, 0.32));

    for (var i = 0; i < streakCount; i++) {
      final xFraction = random.nextDouble();
      final phase = random.nextDouble();
      final fallSpeed = wrapHeight / (5.5 + random.nextDouble() * 2.5);
      final length = size.height * (0.035 + random.nextDouble() * 0.02);
      final drift = size.width * 0.012; // slight diagonal, not a driving-rain slant

      final y = (phase * wrapHeight + animationSeconds * fallSpeed) % wrapHeight - margin;
      final x = xFraction * size.width;

      canvas.drawLine(Offset(x, y), Offset(x + drift, y + length), paint);
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    final random = math.Random(_snowSeed);
    final flakeCount = (10 + intensity * 6).round().clamp(10, 16);
    final margin = size.height * 0.06;
    final wrapHeight = size.height + margin * 2;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: (0.5 * intensity).clamp(0.0, 0.55));

    for (var i = 0; i < flakeCount; i++) {
      final xFraction = random.nextDouble();
      final phase = random.nextDouble();
      // Snow falls noticeably slower than rain and sways gently side to
      // side rather than dropping in a straight line.
      final fallSpeed = wrapHeight / (14 + random.nextDouble() * 8);
      final radius = 1.0 + random.nextDouble() * 1.2;
      final swayAmplitude = size.width * (0.008 + random.nextDouble() * 0.012);
      final swayPeriod = 4.0 + random.nextDouble() * 3.0;
      final swayPhase = random.nextDouble() * 2 * math.pi;

      final y = (phase * wrapHeight + animationSeconds * fallSpeed) % wrapHeight - margin;
      final sway = swayAmplitude * math.sin(2 * math.pi * animationSeconds / swayPeriod + swayPhase);
      final x = xFraction * size.width + sway;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  /// A brief, gentle brightening rather than a bolt graphic or a hard
  /// full-screen flash — occasional and irregular (not a metronome), and
  /// capped at a low peak alpha so it reads as ambient lightning-adjacent
  /// atmosphere, not an event demanding attention.
  void _paintStormFlicker(Canvas canvas, Size size) {
    const slotSeconds = 9.0;
    const flashChance = 0.5;
    const flashHalfWidth = 0.3;
    const peakAlpha = 0.09;

    final slot = (animationSeconds / slotSeconds).floor();
    final slotRandom = math.Random(slot);
    final occurs = slotRandom.nextDouble() < flashChance;
    if (!occurs) return;

    final flashOffset = 1.0 + slotRandom.nextDouble() * (slotSeconds - 3.0);
    final localT = animationSeconds - slot * slotSeconds;
    final distance = (localT - flashOffset).abs();
    if (distance > flashHalfWidth) return;

    final pulse = 1 - distance / flashHalfWidth;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: peakAlpha * pulse),
    );
  }

  @override
  bool shouldRepaint(covariant _PrecipitationPainter oldDelegate) =>
      oldDelegate.intensity != intensity ||
      oldDelegate.kind != kind ||
      oldDelegate.stormFlicker != stormFlicker ||
      oldDelegate.animationSeconds != animationSeconds;
}
