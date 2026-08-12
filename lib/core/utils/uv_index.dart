/// Standard EPA/WHO UV Index category bands — never invented, the same
/// five bands used industry-wide:
///   0–2 Low, 3–5 Moderate, 6–7 High, 8–10 Very High, 11+ Extreme.
library;

/// Rounds [uvIndex] to the nearest whole number for display — Pirate
/// Weather reports a continuous value, but the UV Index is conventionally
/// shown and categorized as a whole number.
int roundUvIndex(double uvIndex) => uvIndex.round();

/// The standard category label for a (rounded) UV Index value.
String uvIndexCategory(int uvIndex) {
  if (uvIndex <= 2) return 'Low';
  if (uvIndex <= 5) return 'Moderate';
  if (uvIndex <= 7) return 'High';
  if (uvIndex <= 10) return 'Very High';
  return 'Extreme';
}
