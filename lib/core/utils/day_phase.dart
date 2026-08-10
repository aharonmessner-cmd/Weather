import 'solar_position.dart';

/// A coarse, human-meaningful label for where the sun is in its daily
/// cycle. Useful for copy ("Sunrise", "6:24 AM") and for picking which
/// metric card to emphasize — **not** for driving sky rendering directly.
/// The sky's actual gradient/stars/glow are continuous functions of
/// [SolarPosition.elevationDegrees]; see `sky_palette_resolver.dart`. Two
/// moments a fraction of a degree apart should never land in visibly
/// different phases here and then render as a hard visual cut — they
/// don't, because nothing downstream switches on this enum for pixels.
enum DayPhase { sunrise, morning, midday, afternoon, sunset, evening, night }

/// Elevation thresholds, in degrees, common to both sides of solar noon.
/// -8° is roughly the point civil twilight has given way to deeper dusk;
/// 2° is comfortably past the moment the sun's disc has cleared the
/// horizon.
const double _twilightEdge = -8;
const double _daylightEdge = 2;

/// Classifies [position] into a [DayPhase], using [middayFraction] (0–1,
/// default 0.8) of that day's peak solar elevation
/// ([solarNoonElevationDegrees]) as the "counts as midday" threshold —
/// scaled per season/latitude rather than a fixed absolute angle, since a
/// clear winter noon at high latitude may never reach a fixed 40–50°.
DayPhase computeDayPhase({
  required SolarPosition position,
  required double solarNoonElevationDegrees,
  double middayFraction = 0.8,
}) {
  final elevation = position.elevationDegrees;
  final middayThreshold = solarNoonElevationDegrees * middayFraction;

  if (elevation >= middayThreshold) return DayPhase.midday;

  if (position.isMorningSide) {
    if (elevation < _twilightEdge) return DayPhase.night;
    if (elevation < _daylightEdge) return DayPhase.sunrise;
    return DayPhase.morning;
  } else {
    if (elevation < _twilightEdge) return DayPhase.night;
    if (elevation < 0) return DayPhase.evening;
    if (elevation < _daylightEdge) return DayPhase.sunset;
    return DayPhase.afternoon;
  }
}
