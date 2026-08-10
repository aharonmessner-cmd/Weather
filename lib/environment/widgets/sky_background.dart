import 'package:flutter/material.dart';

import '../sky_palette.dart';
import 'sky_clouds.dart';
import 'sky_precipitation_overlay.dart';
import 'sky_stars.dart';
import 'sky_sun_moon.dart';

/// Paints one resolved [SkyPalette]: base gradient, horizon glow, stars,
/// sun/moon, clouds, and a light precipitation veil, in back-to-front
/// order. Pure presentation — all the "what should this look like" logic
/// already happened in `resolveSkyPalette`.
class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key, required this.palette});

  final SkyPalette palette;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.topColor, palette.bottomColor],
            ),
          ),
        ),
        if (palette.horizonGlowIntensity > 0.02)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: 1.15,
                colors: [
                  palette.horizonGlowColor.withValues(alpha: (0.5 * palette.horizonGlowIntensity).clamp(0.0, 1.0)),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        SkyStars(opacity: palette.starOpacity),
        SkySunMoon(palette: palette),
        SkyClouds(coverageFraction: palette.cloudCoverageFraction, opacity: palette.cloudOpacity),
        SkyPrecipitationOverlay(intensity: palette.precipitationIntensity),
      ],
    );
  }
}
