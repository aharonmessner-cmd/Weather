import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/utils/uv_index.dart';

void main() {
  group('uvIndexCategory', () {
    test('0-2 is Low', () {
      expect(uvIndexCategory(0), 'Low');
      expect(uvIndexCategory(2), 'Low');
    });

    test('3-5 is Moderate', () {
      expect(uvIndexCategory(3), 'Moderate');
      expect(uvIndexCategory(5), 'Moderate');
    });

    test('6-7 is High', () {
      expect(uvIndexCategory(6), 'High');
      expect(uvIndexCategory(7), 'High');
    });

    test('8-10 is Very High', () {
      expect(uvIndexCategory(8), 'Very High');
      expect(uvIndexCategory(10), 'Very High');
    });

    test('11+ is Extreme', () {
      expect(uvIndexCategory(11), 'Extreme');
      expect(uvIndexCategory(15), 'Extreme');
    });

    test('boundary values are inclusive on the correct edge', () {
      expect(uvIndexCategory(2), 'Low');
      expect(uvIndexCategory(3), 'Moderate');
      expect(uvIndexCategory(5), 'Moderate');
      expect(uvIndexCategory(6), 'High');
      expect(uvIndexCategory(7), 'High');
      expect(uvIndexCategory(8), 'Very High');
      expect(uvIndexCategory(10), 'Very High');
      expect(uvIndexCategory(11), 'Extreme');
    });
  });

  group('roundUvIndex', () {
    test('rounds to the nearest whole number', () {
      expect(roundUvIndex(5.4), 5);
      expect(roundUvIndex(5.5), 6);
      expect(roundUvIndex(0.2), 0);
    });
  });
}
