/// A coarse, app-owned classification of "what the sky is doing."
///
/// The UI renders icons/animations against this enum rather than against
/// NWS's icon URLs or short-forecast text directly, so icon assets and
/// NWS's presentation details can change independently of each other.
enum WeatherCondition {
  clearSky,
  mostlyClear,
  partlyCloudy,
  mostlyCloudy,
  overcast,
  fog,
  drizzle,
  rain,
  rainShowers,
  thunderstorms,
  snow,
  snowShowers,
  sleet,
  freezingRain,
  wintryMix,
  windy,
  hazy,
  smoke,
  dust,
  tornado,
  tropicalStorm,
  hurricane,
  hot,
  cold,
  unknown;

  /// Best-effort mapping from an NWS forecast icon URL (and a short
  /// forecast text fallback) to a [WeatherCondition].
  ///
  /// NWS icon URLs look like
  /// `https://api.weather.gov/icons/land/day/tsra,40?size=medium`, where the
  /// path segment before the query string is one or two `/`-joined codes
  /// (the second used to show a forecast transitioning between conditions)
  /// each optionally suffixed with `,<probability>`. We only need the first
  /// code to pick an icon.
  static WeatherCondition fromNws({String? iconUrl, String? shortForecast}) {
    final code = _extractPrimaryIconCode(iconUrl);
    if (code != null) {
      final fromCode = _fromIconCode(code);
      if (fromCode != null) return fromCode;
    }
    return _fromText(shortForecast) ?? WeatherCondition.unknown;
  }

  static String? _extractPrimaryIconCode(String? iconUrl) {
    if (iconUrl == null) return null;
    final uri = Uri.tryParse(iconUrl);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    if (segments.isEmpty) return null;
    // Last path segment holds the code(s), e.g. "tsra,40" or "few".
    // Some responses join two forecast codes with an additional segment,
    // e.g. ".../day/bkn/tsra,40" — take the final segment either way.
    final last = segments.last;
    final firstCode = last.split(',').first;
    return firstCode.isEmpty ? null : firstCode;
  }

  static WeatherCondition? _fromIconCode(String code) {
    switch (code) {
      case 'skc':
      case 'nskc':
        return WeatherCondition.clearSky;
      case 'few':
        return WeatherCondition.mostlyClear;
      case 'sct':
        return WeatherCondition.partlyCloudy;
      case 'bkn':
        return WeatherCondition.mostlyCloudy;
      case 'ovc':
        return WeatherCondition.overcast;
      case 'fog':
        return WeatherCondition.fog;
      case 'rain_showers':
      case 'rain_showers_hi':
        return WeatherCondition.rainShowers;
      case 'rain':
        return WeatherCondition.rain;
      case 'rain_sleet':
      case 'sleet':
        return WeatherCondition.sleet;
      case 'rain_fzra':
      case 'fzra':
      case 'snow_fzra':
        return WeatherCondition.freezingRain;
      case 'rain_snow':
      case 'snow_sleet':
        return WeatherCondition.wintryMix;
      case 'tsra':
      case 'tsra_sct':
      case 'tsra_hi':
        return WeatherCondition.thunderstorms;
      case 'snow':
      case 'blizzard':
        return WeatherCondition.snow;
      case 'wind_skc':
      case 'wind_few':
      case 'wind_sct':
      case 'wind_bkn':
      case 'wind_ovc':
        return WeatherCondition.windy;
      case 'haze':
        return WeatherCondition.hazy;
      case 'smoke':
        return WeatherCondition.smoke;
      case 'dust':
        return WeatherCondition.dust;
      case 'tornado':
        return WeatherCondition.tornado;
      case 'tropical_storm':
        return WeatherCondition.tropicalStorm;
      case 'hurricane':
        return WeatherCondition.hurricane;
      case 'hot':
        return WeatherCondition.hot;
      case 'cold':
        return WeatherCondition.cold;
      case 'drizzle':
        return WeatherCondition.drizzle;
      default:
        return null;
    }
  }

  static WeatherCondition? _fromText(String? text) {
    if (text == null) return null;
    final lower = text.toLowerCase();
    if (lower.contains('thunderstorm')) return WeatherCondition.thunderstorms;
    if (lower.contains('tornado')) return WeatherCondition.tornado;
    if (lower.contains('hurricane')) return WeatherCondition.hurricane;
    if (lower.contains('freezing rain')) return WeatherCondition.freezingRain;
    if (lower.contains('sleet')) return WeatherCondition.sleet;
    if (lower.contains('snow')) return WeatherCondition.snow;
    if (lower.contains('drizzle')) return WeatherCondition.drizzle;
    if (lower.contains('shower')) return WeatherCondition.rainShowers;
    if (lower.contains('rain')) return WeatherCondition.rain;
    if (lower.contains('fog') || lower.contains('mist')) return WeatherCondition.fog;
    if (lower.contains('haze')) return WeatherCondition.hazy;
    if (lower.contains('smoke')) return WeatherCondition.smoke;
    if (lower.contains('dust') || lower.contains('sand')) return WeatherCondition.dust;
    if (lower.contains('windy') || lower.contains('breezy')) return WeatherCondition.windy;
    if (lower.contains('overcast')) return WeatherCondition.overcast;
    if (lower.contains('mostly cloudy')) return WeatherCondition.mostlyCloudy;
    if (lower.contains('partly cloudy') || lower.contains('partly sunny')) {
      return WeatherCondition.partlyCloudy;
    }
    if (lower.contains('mostly clear') || lower.contains('mostly sunny')) {
      return WeatherCondition.mostlyClear;
    }
    if (lower.contains('clear') || lower.contains('sunny')) return WeatherCondition.clearSky;
    if (lower.contains('cloudy')) return WeatherCondition.mostlyCloudy;
    return null;
  }
}
