import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/minutecast/minute_precipitation_forecast.dart';
import 'package:weather/core/models/minutecast/pirate_weather_minutely.dart';

void main() {
  group('PrecipitationType.fromPirateWeather', () {
    test('maps known type strings', () {
      expect(PrecipitationType.fromPirateWeather('rain'), PrecipitationType.rain);
      expect(PrecipitationType.fromPirateWeather('snow'), PrecipitationType.snow);
      expect(PrecipitationType.fromPirateWeather('sleet'), PrecipitationType.sleet);
    });

    test('null (the dry-minute convention) maps to none', () {
      expect(PrecipitationType.fromPirateWeather(null), PrecipitationType.none);
    });

    test('an unrecognized non-null value maps to unknown rather than throwing', () {
      expect(PrecipitationType.fromPirateWeather('hail'), PrecipitationType.unknown);
    });
  });

  group('PrecipitationIntensity.classify', () {
    test('below the dry threshold is none', () {
      expect(PrecipitationIntensity.classify(0), PrecipitationIntensity.none);
      expect(PrecipitationIntensity.classify(0.05), PrecipitationIntensity.none);
      expect(PrecipitationIntensity.classify(null), PrecipitationIntensity.none);
    });

    test('boundaries are inclusive on the lower edge', () {
      expect(PrecipitationIntensity.classify(0.1), PrecipitationIntensity.light);
      expect(PrecipitationIntensity.classify(2.5), PrecipitationIntensity.moderate);
      expect(PrecipitationIntensity.classify(7.6), PrecipitationIntensity.heavy);
    });

    test('mid-band values classify correctly', () {
      expect(PrecipitationIntensity.classify(1.0), PrecipitationIntensity.light);
      expect(PrecipitationIntensity.classify(5.0), PrecipitationIntensity.moderate);
      expect(PrecipitationIntensity.classify(20.0), PrecipitationIntensity.heavy);
    });
  });

  group('MinutePrecipitationForecast.isMeaningfulPrecipitation', () {
    test('true at/above the dry threshold, false below it', () {
      final wet = MinutePrecipitationForecast(
        time: DateTime.utc(2026),
        type: PrecipitationType.rain,
        intensityMmPerHour: 0.1,
      );
      final dry = MinutePrecipitationForecast(
        time: DateTime.utc(2026),
        type: PrecipitationType.none,
        intensityMmPerHour: 0.05,
      );
      final noData = MinutePrecipitationForecast(time: DateTime.utc(2026), type: PrecipitationType.none);

      expect(wet.isMeaningfulPrecipitation, isTrue);
      expect(dry.isMeaningfulPrecipitation, isFalse);
      expect(noData.isMeaningfulPrecipitation, isFalse);
    });
  });

  test('fromPirateWeather converts a raw entry to the app-level model', () {
    final entry = PirateWeatherMinuteEntry.tryParse({
      'time': 1755000000,
      'precipIntensity': 1.2,
      'precipProbability': 0.6,
      'precipType': 'snow',
    })!;

    final minute = MinutePrecipitationForecast.fromPirateWeather(entry);

    expect(minute.time, entry.time);
    expect(minute.type, PrecipitationType.snow);
    expect(minute.probability, 0.6);
    expect(minute.intensityMmPerHour, 1.2);
  });

  group('JSON round-trip', () {
    test('preserves every field', () {
      final minute = MinutePrecipitationForecast(
        time: DateTime.utc(2026, 8, 11, 10, 51),
        type: PrecipitationType.rain,
        probability: 0.75,
        intensityMmPerHour: 1.4,
      );

      final roundTripped = MinutePrecipitationForecast.tryFromJson(minute.toJson());

      expect(roundTripped, minute);
    });

    test('returns null when time is missing/malformed', () {
      expect(MinutePrecipitationForecast.tryFromJson({'type': 'rain'}), isNull);
      expect(MinutePrecipitationForecast.tryFromJson({'time': 'not-a-date'}), isNull);
    });

    test('an unrecognized cached type string falls back to unknown rather than throwing', () {
      final json = {
        'time': DateTime.utc(2026).toIso8601String(),
        'type': 'some-future-type-this-version-does-not-know',
      };
      final roundTripped = MinutePrecipitationForecast.tryFromJson(json);
      expect(roundTripped!.type, PrecipitationType.unknown);
    });
  });
}
