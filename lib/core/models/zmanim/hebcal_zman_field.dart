/// Every zman field the Hebcal `/zmanim` REST API actually returns in its
/// `times` object, verified directly against Hebcal's own source
/// (`hebcal/hebcal-api-go`'s `zmanim.go` field-order list and
/// `hebcal/hebcal-web`'s published OpenAPI spec) rather than guessed —
/// per the app's rule of never inventing a provider field that doesn't
/// exist. This is the *only* vocabulary the calculation-configuration
/// layer is allowed to reference; nothing above `HebcalZmanimResponse`
/// ever sees Hebcal's raw JSON keys directly.
///
/// Grouped below exactly as Hebcal groups them (a "standard" opinion
/// followed by its named alternates), so the halachic relationship
/// between fields is visible here rather than only in a UI label.
enum HebcalZmanField {
  // Night / dawn
  chatzotNight('chatzotNight'),
  alotHaShachar('alotHaShachar'),
  alosBaalHatanya('alosBaalHatanya'),
  misheyakir('misheyakir'),
  misheyakirMachmir('misheyakirMachmir'),
  dawn('dawn'),

  // Sunrise
  sunrise('sunrise'),
  seaLevelSunrise('seaLevelSunrise'),

  // Shema
  sofZmanShma('sofZmanShma'),
  sofZmanShmaMGA('sofZmanShmaMGA'),
  sofZmanShmaMGA16Point1('sofZmanShmaMGA16Point1'),
  sofZmanShmaMGA19Point8('sofZmanShmaMGA19Point8'),
  sofZmanShmaBaalHatanya('sofZmanShmaBaalHatanya'),

  // Tefilla / Shacharit
  sofZmanTfilla('sofZmanTfilla'),
  sofZmanTfillaMGA('sofZmanTfillaMGA'),
  sofZmanTfillaMGA16Point1('sofZmanTfillaMGA16Point1'),
  sofZmanTfillaMGA19Point8('sofZmanTfillaMGA19Point8'),
  sofZmanTfilaBaalHatanya('sofZmanTfilaBaalHatanya'),

  // Midday
  chatzot('chatzot'),

  // Mincha
  minchaGedola('minchaGedola'),
  minchaGedolaMGA('minchaGedolaMGA'),
  minchaGedolaBaalHatanya('minchaGedolaBaalHatanya'),
  minchaKetana('minchaKetana'),
  minchaKetanaMGA('minchaKetanaMGA'),
  minchaKetanaBaalHatanya('minchaKetanaBaalHatanya'),
  plagHaMincha('plagHaMincha'),
  plagHaminchaBaalHatanya('plagHaminchaBaalHatanya'),

  // Sunset
  seaLevelSunset('seaLevelSunset'),
  sunset('sunset'),

  // Nightfall
  beinHaShmashos('beinHaShmashos'),
  dusk('dusk'),
  tzaisBaalHatanya('tzaisBaalHatanya'),
  tzeit7083deg('tzeit7083deg'),
  tzeit85deg('tzeit85deg'),
  tzeit42min('tzeit42min'),
  tzeit50min('tzeit50min'),
  tzeit72min('tzeit72min');

  const HebcalZmanField(this.apiKey);

  /// The exact string Hebcal uses as the JSON key in its `times` object.
  final String apiKey;

  static HebcalZmanField? tryParse(String? apiKey) {
    if (apiKey == null) return null;
    for (final field in values) {
      if (field.apiKey == apiKey) return field;
    }
    return null;
  }
}
