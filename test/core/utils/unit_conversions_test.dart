import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/utils/unit_conversions.dart';

void main() {
  group('celsiusToFahrenheit', () {
    test('converts freezing and boiling points', () {
      expect(celsiusToFahrenheit(0), closeTo(32, 0.001));
      expect(celsiusToFahrenheit(100), closeTo(212, 0.001));
    });

    test('converts a typical observation value', () {
      expect(celsiusToFahrenheit(32.8), closeTo(91.04, 0.01));
    });
  });

  group('kmhToMph', () {
    test('converts a typical wind speed', () {
      expect(kmhToMph(14.8), closeTo(9.196, 0.01));
    });

    test('zero stays zero', () {
      expect(kmhToMph(0), 0);
    });
  });

  group('metersToMiles', () {
    test('converts standard visibility (10 statute miles)', () {
      expect(metersToMiles(16090), closeTo(10.0, 0.01));
    });
  });

  group('paToInHg', () {
    test('converts standard atmospheric pressure', () {
      expect(paToInHg(101325), closeTo(29.92, 0.01));
    });
  });

  group('mmToInches', () {
    test('converts a small precipitation amount', () {
      expect(mmToInches(25.4), closeTo(1.0, 0.001));
    });
  });

  group('degreesToCompass', () {
    test('maps cardinal and intercardinal directions', () {
      expect(degreesToCompass(0), 'N');
      expect(degreesToCompass(90), 'E');
      expect(degreesToCompass(180), 'S');
      expect(degreesToCompass(270), 'W');
      expect(degreesToCompass(210), 'SSW');
      expect(degreesToCompass(360), 'N');
    });

    test('rounds to the nearest of 16 points', () {
      expect(degreesToCompass(11), 'N');
      expect(degreesToCompass(12), 'NNE');
    });
  });

  group('parseLeadingWindSpeedMph', () {
    test('parses a single value', () {
      expect(parseLeadingWindSpeedMph('10 mph'), 10);
    });

    test('parses the low end of a range', () {
      expect(parseLeadingWindSpeedMph('5 to 10 mph'), 5);
    });

    test('returns null for null or unparsable input', () {
      expect(parseLeadingWindSpeedMph(null), isNull);
      expect(parseLeadingWindSpeedMph('calm'), isNull);
    });
  });
}
