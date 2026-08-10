import 'dart:async';

import 'package:flutter/material.dart';

import '../sky_palette.dart';
import 'sky_clouds.dart';
import 'sky_precipitation_overlay.dart';
import 'sky_stars.dart';
import 'sky_sun_moon.dart';

/// Paints one resolved [SkyPalette]: base gradient (with a subtle
/// dawn/dusk mid-band), horizon glow, stars, sun/moon, clouds, and a
/// precipitation layer, in back-to-front order. Color/opacity logic
/// already happened in `resolveSkyPalette` — this widget's own job is
/// purely presentation, plus owning the one shared, low-frequency clock
/// that drives every animated layer's slow motion (cloud drift, star
/// twinkle, falling rain/snow, storm flicker).
///
/// That clock deliberately ticks at ~4Hz, not display refresh rate: every
/// motion here is so slow that a higher tick rate would only spend more
/// battery/CPU without being visibly smoother. It's a single periodic
/// timer shared by every animated child, rather than one `Ticker` per
/// layer, and it stops entirely when the platform's reduced-motion
/// accessibility setting is on — every layer then just renders its
/// t=0 frame, statically.
class SkyBackground extends StatefulWidget {
  const SkyBackground({super.key, required this.palette});

  final SkyPalette palette;

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground> {
  final Stopwatch _stopwatch = Stopwatch()..start();
  Timer? _timer;
  double _elapsedSeconds = 0;
  bool? _reduceMotion;

  static const _tickInterval = Duration(milliseconds: 250);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
      _syncTimer(reduceMotion);
    }
  }

  void _syncTimer(bool reduceMotion) {
    _timer?.cancel();
    _timer = null;
    if (reduceMotion) {
      if (_elapsedSeconds != 0) setState(() => _elapsedSeconds = 0);
      return;
    }
    _timer = Timer.periodic(_tickInterval, (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds = _stopwatch.elapsedMilliseconds / 1000.0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final t = _reduceMotion == true ? 0.0 : _elapsedSeconds;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.topColor, palette.midColor, palette.bottomColor],
              stops: [0, palette.midColorStop, 1],
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
        RepaintBoundary(child: SkyStars(opacity: palette.starOpacity, animationSeconds: t)),
        SkySunMoon(palette: palette),
        RepaintBoundary(
          child: SkyClouds(
            coverageFraction: palette.cloudCoverageFraction,
            opacity: palette.cloudOpacity,
            animationSeconds: t,
          ),
        ),
        RepaintBoundary(
          child: SkyPrecipitationOverlay(
            intensity: palette.precipitationIntensity,
            kind: palette.precipitationKind,
            stormFlicker: palette.stormFlicker,
            animationSeconds: t,
          ),
        ),
      ],
    );
  }
}
