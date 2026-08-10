import 'dart:math' as math;

import 'solar_position.dart';

/// A day's sunrise/sunset in UTC, or null for either when the sun doesn't
/// cross the horizon that day (polar day/night).
class SunTimes {
  const SunTimes({this.sunrise, this.sunset});

  final DateTime? sunrise;
  final DateTime? sunset;
}

double _degToRad(double deg) => deg * math.pi / 180;
double _radToDeg(double rad) => rad * 180 / math.pi;

/// Computes sunrise/sunset for the UTC calendar day containing [date] at
/// the given [latitude]/[longitude], using the standard sunrise-equation
/// approximation (accurate to within a few minutes — intended for
/// labeling/UI, not navigation).
///
/// This is pure client-side astronomy: no network call, no external API,
/// nothing cached. [date]'s time-of-day is ignored beyond identifying
/// which UTC calendar day to compute for.
SunTimes computeSunTimes({
  required double latitude,
  required double longitude,
  required DateTime date,
}) {
  final utcDate = date.isUtc ? date : date.toUtc();
  final dayStart = DateTime.utc(utcDate.year, utcDate.month, utcDate.day);

  final decl = _degToRad(solarDeclinationDegrees(dayStart));
  final lat = _degToRad(latitude);

  final cosHourAngle = -math.tan(lat) * math.tan(decl);
  if (cosHourAngle < -1 || cosHourAngle > 1) {
    // Sun never sets (cosHourAngle < -1) or never rises (> 1) today.
    return const SunTimes();
  }
  final hourAngleDeg = _radToDeg(math.acos(cosHourAngle));

  final eot = equationOfTimeMinutes(dayStart);
  // Solar noon in UTC clock hours: 12:00 solar time, corrected for this
  // longitude's offset from the nearest UTC hour and the equation of time.
  final solarNoonUtcHours = 12 - longitude / 15 - eot / 60;

  final sunriseUtcHours = solarNoonUtcHours - hourAngleDeg / 15;
  final sunsetUtcHours = solarNoonUtcHours + hourAngleDeg / 15;

  return SunTimes(
    sunrise: _addHours(dayStart, sunriseUtcHours),
    sunset: _addHours(dayStart, sunsetUtcHours),
  );
}

DateTime _addHours(DateTime utcMidnight, double hours) {
  return utcMidnight.add(Duration(milliseconds: (hours * 60 * 60 * 1000).round()));
}
