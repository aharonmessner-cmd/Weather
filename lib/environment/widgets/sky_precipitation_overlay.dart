import 'package:flutter/material.dart';

/// A subtle atmospheric suggestion of precipitation — a soft directional
/// veil, not individual animated raindrops. [intensity] comes straight
/// from [SkyPalette.precipitationIntensity].
///
/// Intentionally minimal for this stage: real particle motion (falling
/// rain/snow, lightning flicker) is Stage 7 (Advanced Atmospheric
/// Polish). This widget exists now so that stage only has to add motion
/// to something already wired up, not invent the layer from scratch.
class SkyPrecipitationOverlay extends StatelessWidget {
  const SkyPrecipitationOverlay({super.key, required this.intensity});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    if (intensity <= 0.03) return const SizedBox.shrink();
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Color.lerp(Colors.transparent, const Color(0xFF3A4A66), intensity * 0.35)!,
            ],
            stops: const [0.4, 1.0],
          ),
        ),
      ),
    );
  }
}
