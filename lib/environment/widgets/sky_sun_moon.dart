import 'package:flutter/material.dart';

import '../sky_palette.dart';

/// The sun or moon, small and "integrated into the sky" — this is
/// deliberately not a hero illustration. Position is continuous, driven
/// by [SkyPalette.sunMoonElevationFraction] (vertical) and
/// [SkyPalette.sunMoonAzimuthDegrees] (horizontal), so it drifts smoothly
/// across the sky rather than jumping between fixed slots.
///
/// Must receive the full sky's box constraints (e.g. a `Stack` with
/// `fit: StackFit.expand`, or explicit `Positioned.fill`), since it
/// aligns itself within whatever box it's given.
class SkySunMoon extends StatelessWidget {
  const SkySunMoon({super.key, required this.palette});

  final SkyPalette palette;

  @override
  Widget build(BuildContext context) {
    if (palette.sunMoonVisibility <= 0.02) return const SizedBox.shrink();

    // Azimuth 90°(east)..270°(west) maps across the visible width; outside
    // that range (possible at high latitude in summer) simply clamps to
    // an edge rather than wrapping — a deliberate simplification for V1.
    final horizontalFraction = ((palette.sunMoonAzimuthDegrees - 90) / 180).clamp(0.0, 1.0);
    final x = -0.82 + horizontalFraction * 1.64;
    // Kept within the top third of the sky even at the horizon (elevation
    // fraction 0) — the hero's location/temperature/H-L content occupies
    // the vertical center of the screen, and the glyph drifting down into
    // that band read as crowding the H/L pill rather than sitting behind
    // it in the environment.
    final y = -0.92 + (1 - palette.sunMoonElevationFraction) * 0.7;

    return Align(
      alignment: Alignment(x, y),
      child: Opacity(
        opacity: palette.sunMoonVisibility,
        child: palette.isSunVisible ? const _SunGlyph() : const _MoonGlyph(),
      ),
    );
  }
}

class _SunGlyph extends StatelessWidget {
  const _SunGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFFFFF3C4), Color(0xFFFFCB4E), Color(0x00FFCB4E)],
          stops: [0, 0.55, 1],
        ),
        boxShadow: [BoxShadow(color: Color(0x66FFC94A), blurRadius: 26, spreadRadius: 4)],
      ),
    );
  }
}

class _MoonGlyph extends StatelessWidget {
  const _MoonGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: CustomPaint(painter: _MoonPainter()),
    );
  }
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final paint = Paint()..color = const Color(0xFFEAEFFF);
    canvas.drawCircle(center, radius, paint);

    // Crescent shading: an offset darker circle punched out via
    // difference blending, cheaper than a path-based crescent.
    final shadowPaint = Paint()
      ..color = const Color(0xFF0B1330)
      ..blendMode = BlendMode.srcOut;
    canvas.saveLayer(Rect.fromCircle(center: center, radius: radius), Paint());
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(Offset(center.dx + radius * 0.55, center.dy - radius * 0.25), radius * 0.9, shadowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) => false;
}
