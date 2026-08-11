/// Standard meteorological liquid-equivalent precipitation rate bands
/// (mm/h) — not invented for this app. Used to classify intensity and to
/// decide what counts as "meaningfully precipitating" versus dry, for
/// every derived MinuteCast state (starting/ending/active/dry).
class MinuteCastThresholds {
  const MinuteCastThresholds._();

  /// Below this rate, a minute is treated as dry — not "starting",
  /// "ending", or "currently raining/snowing".
  static const double dryMmPerHour = 0.1;

  /// [dryMmPerHour, lightMaxMmPerHour) is "light".
  static const double lightMaxMmPerHour = 2.5;

  /// [lightMaxMmPerHour, moderateMaxMmPerHour) is "moderate";
  /// >= moderateMaxMmPerHour is "heavy".
  static const double moderateMaxMmPerHour = 7.6;

  /// An "ending" transition must stay below [dryMmPerHour] for at least
  /// this many consecutive minutes — within the data actually available —
  /// before it's reported as ending. Guards against one noisy dry-looking
  /// minute in the middle of an otherwise-active precipitation event
  /// flipping the summary to "ending" and back.
  static const int endingPersistenceMinutes = 3;

  /// "Starting in 1 min" / "ending in 1 min" read as false precision this
  /// data can't really promise minute-exact — collapse anything this
  /// close into "starting now" / "ending soon" instead.
  static const int nowThresholdMinutes = 2;
}
