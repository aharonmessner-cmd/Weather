import 'hebcal_zman_field.dart';

/// A short, human-readable label for *which calculation* a
/// [HebcalZmanField] represents — distinct from a [ZmanDefinition]'s
/// `displayName` (the user-facing row name). Used only in Advanced Zmanim
/// settings' "change calculation source" picker, so a user swapping the
/// opinion behind a row can see exactly what they're choosing between
/// (e.g. "16.1° (standard)" vs. "Baal HaTanya (16.9°)") rather than a raw
/// Hebcal field key like `alosBaalHatanya`.
String hebcalZmanFieldLabel(HebcalZmanField field) {
  return switch (field) {
    HebcalZmanField.chatzotNight => 'Sunset + 6 hours',
    HebcalZmanField.alotHaShachar => '16.1° (standard)',
    HebcalZmanField.alosBaalHatanya => 'Baal HaTanya (16.9°)',
    HebcalZmanField.misheyakir => '11.5° (standard)',
    HebcalZmanField.misheyakirMachmir => '10.2° (machmir)',
    HebcalZmanField.dawn => 'Civil dawn (6°)',
    HebcalZmanField.sunrise => 'Standard',
    HebcalZmanField.seaLevelSunrise => 'Sea level',
    HebcalZmanField.sofZmanShma => 'Gra',
    HebcalZmanField.sofZmanShmaMGA => 'Magen Avraham (72 min)',
    HebcalZmanField.sofZmanShmaMGA16Point1 => 'Magen Avraham (16.1°)',
    HebcalZmanField.sofZmanShmaMGA19Point8 => 'Magen Avraham (19.8°)',
    HebcalZmanField.sofZmanShmaBaalHatanya => 'Baal HaTanya',
    HebcalZmanField.sofZmanTfilla => 'Gra',
    HebcalZmanField.sofZmanTfillaMGA => 'Magen Avraham (72 min)',
    HebcalZmanField.sofZmanTfillaMGA16Point1 => 'Magen Avraham (16.1°)',
    HebcalZmanField.sofZmanTfillaMGA19Point8 => 'Magen Avraham (19.8°)',
    HebcalZmanField.sofZmanTfilaBaalHatanya => 'Baal HaTanya',
    HebcalZmanField.chatzot => 'Standard',
    HebcalZmanField.minchaGedola => 'Gra',
    HebcalZmanField.minchaGedolaMGA => 'Magen Avraham',
    HebcalZmanField.minchaGedolaBaalHatanya => 'Baal HaTanya',
    HebcalZmanField.minchaKetana => 'Gra',
    HebcalZmanField.minchaKetanaMGA => 'Magen Avraham',
    HebcalZmanField.minchaKetanaBaalHatanya => 'Baal HaTanya',
    HebcalZmanField.plagHaMincha => 'Gra',
    HebcalZmanField.plagHaminchaBaalHatanya => 'Baal HaTanya',
    HebcalZmanField.seaLevelSunset => 'Sea level',
    HebcalZmanField.sunset => 'Standard',
    HebcalZmanField.beinHaShmashos => 'Twilight boundary (7.083°)',
    HebcalZmanField.dusk => 'Civil dusk (6°)',
    HebcalZmanField.tzaisBaalHatanya => 'Baal HaTanya (6°)',
    HebcalZmanField.tzeit7083deg => '3 medium stars (7.083°)',
    HebcalZmanField.tzeit85deg => '8.5°',
    HebcalZmanField.tzeit42min => '42 minutes',
    HebcalZmanField.tzeit50min => '50 minutes',
    HebcalZmanField.tzeit72min => '72 minutes (Rabbeinu Tam)',
  };
}
