import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/minutecast/pirate_weather_minutely.dart';

void main() {
  group('PirateWeatherMinuteEntry.tryParse', () {
    test('parses a fully-populated minute', () {
      final entry = PirateWeatherMinuteEntry.tryParse({
        'time': 1755000000,
        'precipIntensity': 1.5,
        'precipProbability': 0.8,
        'precipType': 'rain',
      });

      expect(entry, isNotNull);
      expect(entry!.time, DateTime.fromMillisecondsSinceEpoch(1755000000 * 1000, isUtc: true));
      expect(entry.time.isUtc, isTrue);
      expect(entry.precipIntensity, 1.5);
      expect(entry.precipProbability, 0.8);
      expect(entry.precipType, 'rain');
    });

    test('a dry minute typically omits precipType entirely', () {
      final entry = PirateWeatherMinuteEntry.tryParse({
        'time': 1755000000,
        'precipIntensity': 0,
        'precipProbability': 0,
      });

      expect(entry, isNotNull);
      expect(entry!.precipType, isNull);
    });

    test('returns null when time is missing', () {
      expect(PirateWeatherMinuteEntry.tryParse({'precipIntensity': 1.0}), isNull);
    });

    test('returns null when time is not numeric', () {
      expect(PirateWeatherMinuteEntry.tryParse({'time': 'not-a-number'}), isNull);
    });

    test('treats a missing/malformed precipIntensity or precipProbability as null, not zero or a crash', () {
      final entry = PirateWeatherMinuteEntry.tryParse({'time': 1755000000, 'precipIntensity': 'garbage'});
      expect(entry, isNotNull);
      expect(entry!.precipIntensity, isNull);
    });
  });

  group('PirateWeatherResponse.tryParse', () {
    test('parses a well-formed minutely block', () {
      final response = PirateWeatherResponse.tryParse({
        'minutely': {
          'data': [
            {'time': 1755000000, 'precipIntensity': 0, 'precipProbability': 0},
            {'time': 1755000060, 'precipIntensity': 1.0, 'precipProbability': 0.5, 'precipType': 'rain'},
          ],
        },
      });

      expect(response, isNotNull);
      expect(response!.minutes, hasLength(2));
    });

    test('returns null when the minutely block is entirely missing', () {
      expect(PirateWeatherResponse.tryParse({'currently': {}}), isNull);
    });

    test('returns null when minutely.data is missing', () {
      expect(PirateWeatherResponse.tryParse({'minutely': {}}), isNull);
    });

    test('returns null when minutely.data is not a list', () {
      expect(PirateWeatherResponse.tryParse({'minutely': {'data': 'oops'}}), isNull);
    });

    test('returns null when minutely.data is an empty list', () {
      expect(PirateWeatherResponse.tryParse({'minutely': {'data': <dynamic>[]}}), isNull);
    });

    test('skips individual malformed entries rather than failing the whole parse', () {
      final response = PirateWeatherResponse.tryParse({
        'minutely': {
          'data': [
            {'precipIntensity': 1.0}, // missing time -- skipped
            {'time': 1755000060, 'precipIntensity': 1.0},
          ],
        },
      });

      expect(response, isNotNull);
      expect(response!.minutes, hasLength(1));
    });

    test('does not throw on a completely malformed top-level response', () {
      expect(PirateWeatherResponse.tryParse(<String, dynamic>{}), isNull);
    });
  });

  group('PirateWeatherResponse.tryParse: uvIndex', () {
    test('parses currently.uvIndex alongside minutely data', () {
      final response = PirateWeatherResponse.tryParse({
        'minutely': {
          'data': [
            {'time': 1755000000, 'precipIntensity': 0, 'precipProbability': 0},
          ],
        },
        'currently': {'uvIndex': 7},
      });

      expect(response!.uvIndex, 7.0);
    });

    test('a missing currently block leaves uvIndex null without failing the parse', () {
      final response = PirateWeatherResponse.tryParse({
        'minutely': {
          'data': [
            {'time': 1755000000, 'precipIntensity': 0, 'precipProbability': 0},
          ],
        },
      });

      expect(response, isNotNull);
      expect(response!.uvIndex, isNull);
    });

    test('a malformed currently.uvIndex leaves uvIndex null rather than crashing', () {
      final response = PirateWeatherResponse.tryParse({
        'minutely': {
          'data': [
            {'time': 1755000000, 'precipIntensity': 0, 'precipProbability': 0},
          ],
        },
        'currently': {'uvIndex': 'not-a-number'},
      });

      expect(response, isNotNull);
      expect(response!.uvIndex, isNull);
    });
  });
}
