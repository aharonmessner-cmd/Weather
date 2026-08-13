import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/allergy/allergy_level.dart';

void main() {
  group('dustLevelFromMicrogramsPerCubicMeter', () {
    test('values under 15 are Low', () {
      expect(dustLevelFromMicrogramsPerCubicMeter(0), AllergyLevel.low);
      expect(dustLevelFromMicrogramsPerCubicMeter(14.9), AllergyLevel.low);
    });

    test('values from 15 up to (not including) 50 are Moderate', () {
      expect(dustLevelFromMicrogramsPerCubicMeter(15), AllergyLevel.moderate);
      expect(dustLevelFromMicrogramsPerCubicMeter(49.9), AllergyLevel.moderate);
    });

    test('values 50 and above are High', () {
      expect(dustLevelFromMicrogramsPerCubicMeter(50), AllergyLevel.high);
      expect(dustLevelFromMicrogramsPerCubicMeter(500), AllergyLevel.high);
    });

    test('boundary values are inclusive on the correct edge', () {
      expect(dustLevelFromMicrogramsPerCubicMeter(15), AllergyLevel.moderate);
      expect(dustLevelFromMicrogramsPerCubicMeter(50), AllergyLevel.high);
    });
  });

  group('AllergyLevel.label', () {
    test('matches the expected display strings', () {
      expect(AllergyLevel.low.label, 'Low');
      expect(AllergyLevel.moderate.label, 'Moderate');
      expect(AllergyLevel.high.label, 'High');
    });
  });
}
