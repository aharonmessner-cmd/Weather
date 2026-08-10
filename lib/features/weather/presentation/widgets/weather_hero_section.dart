import 'package:flutter/material.dart';

import '../../../../core/models/current_conditions.dart';
import '../../../../environment/weather_environment.dart';
import '../../../../theme/app_typography.dart';
import 'temperature_hero.dart';
import 'weather_glyphs.dart';

/// The Weather tab's hero: location, temperature, condition, H/L — sitting
/// directly on the [WeatherEnvironment] with no card around it. Reads its
/// text/icon color from the sky's own resolved brightness
/// ([WeatherEnvironment.paletteOf]), not from [ThemeMode] — see the module
/// doc on [WeatherEnvironment] for why those are different things.
class WeatherHeroSection extends StatelessWidget {
  const WeatherHeroSection({
    super.key,
    required this.locationName,
    required this.current,
    this.locationSwitcher,
  });

  final String locationName;
  final CurrentConditions current;

  /// Slot for the favorites city pager (Stage 4) — omitted here so this
  /// widget doesn't depend on locations state.
  final Widget? locationSwitcher;

  @override
  Widget build(BuildContext context) {
    final palette = WeatherEnvironment.paletteOf(context);
    final isDarkSky = palette.heroContentBrightness == Brightness.dark;
    final contentColor = isDarkSky ? Colors.white : const Color(0xFF12141C);
    final secondaryColor = contentColor.withValues(alpha: 0.62);
    final pillBackground = contentColor.withValues(alpha: isDarkSky ? 0.14 : 0.08);
    final pillBorder = contentColor.withValues(alpha: isDarkSky ? 0.18 : 0.12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            locationName,
            style: TextStyle(
              fontFamily: AppTypography.fontDisplay,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: contentColor,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (locationSwitcher != null) ...[
            const SizedBox(height: 6),
            locationSwitcher!,
          ],
          const SizedBox(height: 4),
          Center(
            child: TemperatureHero(
              temperatureFahrenheit: current.temperatureFahrenheit?.round(),
              contentColor: contentColor,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WeatherGlyph(condition: current.condition, isDaytime: current.isDaytime ?? true, size: 22, color: secondaryColor),
              const SizedBox(width: 6),
              if (current.conditionText != null)
                // Flexible + ellipsis rather than a fixed-size shrink: NWS
                // condition text can run long ("Chance Light Rain then
                // Slight Chance Snow"), and truncating keeps it legible at
                // a large system text scale instead of shrinking it small.
                Flexible(
                  child: Text(
                    current.conditionText!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.fontDisplay,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: secondaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (current.todayHighFahrenheit != null || current.todayLowFahrenheit != null)
            // FittedBox: on a narrow phone at a large system text scale,
            // the pill's natural content width can exceed the space the
            // Column offers it — scaling the whole pill down (rather than
            // letting it overflow) keeps it intact instead of clipping.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: pillBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: pillBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('H', style: TextStyle(fontFamily: AppTypography.fontBody, fontSize: 13, color: secondaryColor)),
                    const SizedBox(width: 4),
                    Text(
                      '${current.todayHighFahrenheit ?? '--'}°',
                      style: TextStyle(fontFamily: AppTypography.fontDisplay, fontSize: 14, fontWeight: FontWeight.w600, color: contentColor),
                    ),
                    const SizedBox(width: 8),
                    Text('L', style: TextStyle(fontFamily: AppTypography.fontBody, fontSize: 13, color: secondaryColor)),
                    const SizedBox(width: 4),
                    Text(
                      '${current.todayLowFahrenheit ?? '--'}°',
                      style: TextStyle(fontFamily: AppTypography.fontDisplay, fontSize: 14, fontWeight: FontWeight.w600, color: contentColor),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
