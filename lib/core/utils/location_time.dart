import 'package:timezone/timezone.dart' as tz;

/// Resolves [instant] (an absolute UTC instant) to wall-clock time at
/// [timeZone] (an IANA identifier, e.g. `"America/New_York"`) — for
/// *display only*. All comparisons/ordering elsewhere in the app must
/// keep using the instant itself, never this.
///
/// Falls back to the device's local time zone when [timeZone] is null or
/// unrecognized (cached data from before locations carried a time zone,
/// or a lookup failure) — the same behavior every display already had
/// before this existed, so this never regresses anything, it only fixes
/// the case where a real time zone is known.
DateTime resolveLocationTime(DateTime instant, String? timeZone) {
  if (timeZone == null) return instant.toLocal();
  try {
    return tz.TZDateTime.from(instant, tz.getLocation(timeZone));
  } catch (_) {
    return instant.toLocal();
  }
}

/// `"3:41 PM"`
String formatClockTime(DateTime instant, String? timeZone) {
  final local = resolveLocationTime(instant, timeZone);
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $suffix';
}

/// `"3PM"` — hour-only, matching the hourly forecast strip's compact style.
String formatClockHour(DateTime instant, String? timeZone) {
  final local = resolveLocationTime(instant, timeZone);
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final suffix = local.hour < 12 ? 'AM' : 'PM';
  return '$hour$suffix';
}

/// `"3:41"` — no AM/PM, for compact same-meridiem-implied displays like
/// the MinuteCast timeline (nothing in a ~60 minute window is likely to
/// need the disambiguation, matching how AccuWeather-style minute
/// timelines are conventionally labeled).
String formatClockTimeCompact(DateTime instant, String? timeZone) {
  final local = resolveLocationTime(instant, timeZone);
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
