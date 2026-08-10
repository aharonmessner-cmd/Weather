import 'package:flutter/material.dart';

import '../../../../theme/app_typography.dart';
import 'degree_glyph.dart';

/// The temperature as the primary typographic object — tall, bold,
/// architectural, un-boxed. This is the hero; nothing else on the Weather
/// screen should visually compete with it.
///
/// Height comes from three things working together, not one dramatic
/// trick: a large reference font size, a heavy weight with tight negative
/// letter-spacing, and a modest vertical stretch on top. Pushing the
/// stretch factor alone to get "tall" reads as distorted text, not custom
/// typography — so it stays a finishing touch here, not the mechanism.
/// The weight is deliberately bold rather than the thin/light styles
/// typical of this genre of oversized display type — against a bright,
/// busy sky background a thin stroke loses contrast and presence, so this
/// leans heavier to stay legible and confident.
///
/// Sizing is a fixed, generous reference size wrapped in a [FittedBox]
/// rather than a hand-computed "font size as a fraction of width" formula
/// — the latter is fragile (it's easy to under/overestimate how wide "72°"
/// vs. "-10°" vs. "100°" actually render) and either overflows or wastes
/// space. `FittedBox.scaleDown` scales the whole composition — stretched
/// digits and degree glyph together — smoothly and continuously to fit
/// whatever box it's given, which is also exactly the "dynamically
/// scaled" behavior wanted across phone/tablet/desktop (Stage 5).
///
/// Accessibility: the stylized glyph run opts out of system text scaling
/// (it's a graphic, not reflowable body copy) and excludes itself from
/// the semantics tree, replaced by a single explicit label carrying the
/// literal value — screen readers get "72 degrees Fahrenheit" regardless
/// of how the digits are stretched and scaled on screen.
class TemperatureHero extends StatelessWidget {
  const TemperatureHero({
    super.key,
    required this.temperatureFahrenheit,
    required this.contentColor,
  });

  /// Already-rounded-for-display value; pass null when unavailable.
  final int? temperatureFahrenheit;
  final Color contentColor;

  static const double _referenceFontSize = 200;
  static const double _verticalStretch = 1.18;

  @override
  Widget build(BuildContext context) {
    final value = temperatureFahrenheit;
    final displayText = value?.toString() ?? '--';
    final semanticLabel = value != null ? '$value degrees Fahrenheit' : 'Temperature unavailable';

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(1.0, _verticalStretch, 1.0),
              child: Text(
                displayText,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: AppTypography.fontDisplay,
                  fontWeight: FontWeight.w700,
                  fontSize: _referenceFontSize,
                  height: 0.88,
                  letterSpacing: -_referenceFontSize * 0.02,
                  color: contentColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: _referenceFontSize * 0.10,
                left: _referenceFontSize * 0.02,
              ),
              child: DegreeGlyph(size: _referenceFontSize * 0.12, color: contentColor),
            ),
          ],
        ),
      ),
    );
  }
}
