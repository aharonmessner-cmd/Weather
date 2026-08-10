import 'dart:math' as math;

/// Continuous solar geometry: how high the sun is above the horizon
/// ([elevationDegrees], negative below it) and where along the horizon it
/// sits ([azimuthDegrees], 0=north through 90=east, 180=south, 270=west).
///
/// This is the primary continuous signal the sky environment renders from
/// — everything from gradient color to star opacity to sun/moon placement
/// is a function of [elevationDegrees], not of a bucketed time-of-day
/// label. See `lib/environment/sky_palette_resolver.dart`.
class SolarPosition {
  const SolarPosition({required this.elevationDegrees, required this.azimuthDegrees, required this.hourAngleDegrees});

  final double elevationDegrees;
  final double azimuthDegrees;

  /// Hour angle in degrees: negative before solar noon, positive after.
  /// Exposed because it's the cheapest way to tell "morning side" from
  /// "afternoon side" at the same elevation (sunrise vs. sunset look the
  /// same in elevation alone).
  final double hourAngleDegrees;

  bool get isMorningSide => hourAngleDegrees < 0;
}

double _degToRad(double deg) => deg * math.pi / 180;
double _radToDeg(double rad) => rad * 180 / math.pi;

/// Day-of-year as a fractional value (1.0 = Jan 1st 00:00 UTC), used by
/// the declination and equation-of-time approximations below.
double _dayOfYear(DateTime utc) {
  final startOfYear = DateTime.utc(utc.year, 1, 1);
  return utc.difference(startOfYear).inMinutes / (24 * 60) + 1;
}

/// Solar declination in degrees (Cooper's equation) — the sun's angle
/// relative to the equatorial plane, which drives both season and the
/// length of day at a given latitude.
double solarDeclinationDegrees(DateTime utc) {
  final n = _dayOfYear(utc);
  return 23.45 * math.sin(_degToRad(360 / 365 * (284 + n)));
}

/// Equation of time in minutes — the difference between apparent solar
/// time and mean (clock) solar time, caused by Earth's elliptical orbit
/// and axial tilt.
double equationOfTimeMinutes(DateTime utc) {
  final n = _dayOfYear(utc);
  final b = _degToRad(360 / 365 * (n - 81));
  return 9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b);
}

/// Local apparent solar hour angle in degrees at [utcTime] for a given
/// [longitude]: 0 at solar noon, negative in the morning, positive in the
/// afternoon, moving 15°/hour.
double solarHourAngleDegrees({required double longitude, required DateTime utcTime}) {
  final utcHours = utcTime.hour + utcTime.minute / 60 + utcTime.second / 3600;
  final eot = equationOfTimeMinutes(utcTime);
  // Solar time at this longitude: UTC clock time, shifted by longitude
  // (15° per hour) and the equation-of-time correction.
  final solarTimeHours = utcHours + longitude / 15 + eot / 60;
  return (solarTimeHours - 12) * 15;
}

/// The sun's approximate elevation/azimuth at [utcTime] for the given
/// [latitude]/[longitude]. Accurate to within a fraction of a degree —
/// intended for driving UI gradients, not navigation.
SolarPosition computeSolarPosition({
  required double latitude,
  required double longitude,
  required DateTime utcTime,
}) {
  final lat = _degToRad(latitude);
  final decl = _degToRad(solarDeclinationDegrees(utcTime));
  final hourAngleDeg = solarHourAngleDegrees(longitude: longitude, utcTime: utcTime);
  final hourAngle = _degToRad(hourAngleDeg);

  final sinElevation = math.sin(lat) * math.sin(decl) + math.cos(lat) * math.cos(decl) * math.cos(hourAngle);
  final elevation = _radToDeg(math.asin(sinElevation.clamp(-1.0, 1.0)));

  final cosElevation = math.cos(_degToRad(elevation));
  double azimuth;
  if (cosElevation.abs() < 1e-6) {
    azimuth = 180;
  } else {
    final cosAzimuth = (math.sin(decl) - math.sin(_degToRad(elevation)) * math.sin(lat)) / (cosElevation * math.cos(lat));
    final azimuthRaw = _radToDeg(math.acos(cosAzimuth.clamp(-1.0, 1.0)));
    azimuth = hourAngleDeg > 0 ? 360 - azimuthRaw : azimuthRaw;
  }

  return SolarPosition(elevationDegrees: elevation, azimuthDegrees: azimuth, hourAngleDegrees: hourAngleDeg);
}

/// The sun's peak elevation for the day at [latitude] (i.e. its elevation
/// at solar noon), used to scale "how high counts as midday" per
/// season/latitude rather than against a fixed absolute angle — a clear
/// winter noon at high latitude may never reach 40°.
double solarNoonElevationDegrees({required double latitude, required DateTime utcDate}) {
  final decl = solarDeclinationDegrees(utcDate);
  return 90 - (latitude - decl).abs();
}
