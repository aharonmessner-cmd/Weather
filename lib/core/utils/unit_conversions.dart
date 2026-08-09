/// Unit conversions between the SI units NWS observations are reported in
/// and the US customary units this app displays.
///
/// Forecast endpoints already come back in US units (the API defaults to
/// `units=us`), but observations are always SI, so the app-model layer
/// needs to convert those explicitly.
library;

double celsiusToFahrenheit(double celsius) => celsius * 9 / 5 + 32;

double kmhToMph(double kmh) => kmh * 0.621371;

double metersToMiles(double meters) => meters * 0.000621371;

double paToInHg(double pascals) => pascals * 0.0002953;

double mmToInches(double mm) => mm * 0.0393701;

/// Converts a wind direction in degrees (0-360, 0/360 = North) to a
/// 16-point compass abbreviation, e.g. `210` -> `"SSW"`.
String degreesToCompass(double degrees) {
  const directions = [
    'N', 'NNE', 'NE', 'ENE',
    'E', 'ESE', 'SE', 'SSE',
    'S', 'SSW', 'SW', 'WSW',
    'W', 'WNW', 'NW', 'NNW',
  ];
  final normalized = degrees % 360;
  final index = ((normalized / 22.5) + 0.5).floor() % 16;
  return directions[index];
}

/// Parses the leading number out of an NWS forecast-period wind speed
/// string, e.g. `"10 mph"` -> `10`, `"10 to 15 mph"` -> `10`. Returns null
/// if no leading number can be found.
double? parseLeadingWindSpeedMph(String? nwsWindSpeed) {
  if (nwsWindSpeed == null) return null;
  final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(nwsWindSpeed);
  if (match == null) return null;
  return double.tryParse(match.group(1)!);
}
