import 'hebcal_zman_field.dart';

/// Groups of [HebcalZmanField]s that represent genuine halachic-opinion
/// alternatives for the *same* zman — e.g. Alos per the standard 16.1°
/// definition vs. the Baal HaTanya opinion. Used by Advanced Zmanim
/// settings to offer "change the calculation source" as a constrained
/// choice among real alternatives for that row, never an arbitrary swap
/// to an unrelated zman (Netz's row should never be swappable to Chatzot,
/// for instance).
///
/// Grouped by literally mirroring how Hebcal's own API source code groups
/// them (`timesOrder`'s standard-then-named-alternates runs, and
/// `tzeitOrder` as its own distinct group) — never an invented grouping.
/// A field with no real alternate (e.g. [HebcalZmanField.chatzot], a
/// single well-defined astronomical midpoint with no halachic dispute)
/// simply isn't listed below and [alternativesFor] returns just itself.
const List<List<HebcalZmanField>> zmanCalculationGroups = [
  [HebcalZmanField.alotHaShachar, HebcalZmanField.alosBaalHatanya],
  [HebcalZmanField.misheyakir, HebcalZmanField.misheyakirMachmir],
  [HebcalZmanField.sunrise, HebcalZmanField.seaLevelSunrise],
  [
    HebcalZmanField.sofZmanShma,
    HebcalZmanField.sofZmanShmaMGA,
    HebcalZmanField.sofZmanShmaMGA16Point1,
    HebcalZmanField.sofZmanShmaMGA19Point8,
    HebcalZmanField.sofZmanShmaBaalHatanya,
  ],
  [
    HebcalZmanField.sofZmanTfilla,
    HebcalZmanField.sofZmanTfillaMGA,
    HebcalZmanField.sofZmanTfillaMGA16Point1,
    HebcalZmanField.sofZmanTfillaMGA19Point8,
    HebcalZmanField.sofZmanTfilaBaalHatanya,
  ],
  [HebcalZmanField.minchaGedola, HebcalZmanField.minchaGedolaMGA, HebcalZmanField.minchaGedolaBaalHatanya],
  [HebcalZmanField.minchaKetana, HebcalZmanField.minchaKetanaMGA, HebcalZmanField.minchaKetanaBaalHatanya],
  [HebcalZmanField.plagHaMincha, HebcalZmanField.plagHaminchaBaalHatanya],
  [HebcalZmanField.sunset, HebcalZmanField.seaLevelSunset],
  [
    HebcalZmanField.tzeit7083deg,
    HebcalZmanField.tzeit85deg,
    HebcalZmanField.tzeit42min,
    HebcalZmanField.tzeit50min,
    HebcalZmanField.tzeit72min,
  ],
];

/// The full set of real alternatives for [field], including [field]
/// itself — always at least `[field]`, never empty.
List<HebcalZmanField> alternativesFor(HebcalZmanField field) {
  for (final group in zmanCalculationGroups) {
    if (group.contains(field)) return group;
  }
  return [field];
}
