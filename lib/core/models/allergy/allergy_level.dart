/// A coarse, human-meaningful classification of dust concentration in the
/// air — the only thing this app currently has a legitimate data source
/// for (see `AllergyClient`/`open_meteo_air_quality.dart`). There is no
/// single official "consumer dust index" the way there is for UV (see
/// `core/utils/uv_index.dart`), so [dustLevelFromMicrogramsPerCubicMeter]
/// is a deliberately simple three-band approximation loosely aligned with
/// common PM10 air-quality guidance (WHO/EPA "good"/"moderate"/"elevated"
/// ranges for particulate matter), not a certified index.
enum AllergyLevel {
  low,
  moderate,
  high;

  String get label => switch (this) {
        AllergyLevel.low => 'Low',
        AllergyLevel.moderate => 'Moderate',
        AllergyLevel.high => 'High',
      };
}

/// Buckets a surface dust concentration (µg/m³, as reported by Open-Meteo's
/// Air Quality API) into a simple three-tier [AllergyLevel]. Thresholds are
/// a reasonable simplification, not a scientific/regulatory standard --
/// good enough for "should I expect dust to be noticeable today," not for
/// health guidance.
AllergyLevel dustLevelFromMicrogramsPerCubicMeter(double value) {
  if (value < 15) return AllergyLevel.low;
  if (value < 50) return AllergyLevel.moderate;
  return AllergyLevel.high;
}
