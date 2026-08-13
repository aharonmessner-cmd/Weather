import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/allergy/open_meteo_air_quality.dart';

void main() {
  group('OpenMeteoAirQualityResponse.tryParse', () {
    test('parses a well-formed current.dust value', () {
      final response = OpenMeteoAirQualityResponse.tryParse({
        'current': {'time': '2026-08-13T12:00', 'dust': 12.3},
      });

      expect(response, isNotNull);
      expect(response!.dustMicrogramsPerCubicMeter, 12.3);
    });

    test('a missing dust field leaves it null without failing the parse', () {
      final response = OpenMeteoAirQualityResponse.tryParse({
        'current': {'time': '2026-08-13T12:00'},
      });

      expect(response, isNotNull);
      expect(response!.dustMicrogramsPerCubicMeter, isNull);
    });

    test('a malformed (non-numeric) dust value is treated as null, not a crash', () {
      final response = OpenMeteoAirQualityResponse.tryParse({
        'current': {'dust': 'not-a-number'},
      });

      expect(response, isNotNull);
      expect(response!.dustMicrogramsPerCubicMeter, isNull);
    });

    test('returns null when the current block is missing entirely', () {
      expect(OpenMeteoAirQualityResponse.tryParse({}), isNull);
    });

    test('returns null when current is the wrong type', () {
      expect(OpenMeteoAirQualityResponse.tryParse({'current': 'nope'}), isNull);
    });
  });
}
