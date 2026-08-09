import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/weather_condition.dart';

void main() {
  group('WeatherCondition.fromNws', () {
    test('maps a plain icon code', () {
      expect(
        WeatherCondition.fromNws(iconUrl: 'https://api.weather.gov/icons/land/day/skc?size=medium'),
        WeatherCondition.clearSky,
      );
    });

    test('maps an icon code with a probability suffix', () {
      expect(
        WeatherCondition.fromNws(iconUrl: 'https://api.weather.gov/icons/land/day/tsra,40?size=medium'),
        WeatherCondition.thunderstorms,
      );
    });

    test('uses the first of two combined forecast-transition codes', () {
      expect(
        WeatherCondition.fromNws(
          iconUrl: 'https://api.weather.gov/icons/land/night/tsra,30/tsra_hi,20?size=medium',
        ),
        WeatherCondition.thunderstorms,
      );
    });

    test('falls back to shortForecast text when the icon URL is missing', () {
      expect(
        WeatherCondition.fromNws(shortForecast: 'Chance Showers And Thunderstorms'),
        WeatherCondition.thunderstorms,
      );
    });

    test('falls back to shortForecast text when the icon code is unrecognized', () {
      expect(
        WeatherCondition.fromNws(
          iconUrl: 'https://api.weather.gov/icons/land/day/totally_new_code?size=medium',
          shortForecast: 'Sunny',
        ),
        WeatherCondition.clearSky,
      );
    });

    test('returns unknown when nothing is parseable', () {
      expect(WeatherCondition.fromNws(), WeatherCondition.unknown);
      expect(WeatherCondition.fromNws(iconUrl: '', shortForecast: ''), WeatherCondition.unknown);
    });

    test('malformed icon URL does not throw', () {
      expect(
        () => WeatherCondition.fromNws(iconUrl: 'not a valid uri at all'),
        returnsNormally,
      );
    });
  });
}
