import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/allergy/allergy_data.dart';
import 'package:weather/core/models/allergy/allergy_level.dart';
import 'package:weather/core/models/location.dart';

const _dc = Location(id: 'dc', name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);

void main() {
  group('AllergyData JSON round-trip', () {
    test('preserves all fields through toJson/tryFromJson', () {
      final data = AllergyData(
        generatedAt: DateTime.utc(2026, 8, 13, 12),
        location: _dc,
        source: AllergySource.openMeteo,
        dustMicrogramsPerCubicMeter: 22.5,
      );

      final roundTripped = AllergyData.tryFromJson(data.toJson());

      expect(roundTripped, data);
    });

    test('a null dust value round-trips as null, not zero', () {
      final data = AllergyData(
        generatedAt: DateTime.utc(2026, 8, 13, 12),
        location: _dc,
        source: AllergySource.openMeteo,
      );

      final roundTripped = AllergyData.tryFromJson(data.toJson());

      expect(roundTripped!.dustMicrogramsPerCubicMeter, isNull);
    });

    test('returns null for malformed cached JSON rather than throwing', () {
      expect(AllergyData.tryFromJson({'generatedAt': 'not-a-date'}), isNull);
      expect(AllergyData.tryFromJson({}), isNull);
    });
  });

  group('AllergyData.dustLevel', () {
    test('derives the level from the concentration', () {
      final data = AllergyData(
        generatedAt: DateTime.utc(2026, 8, 13, 12),
        location: _dc,
        source: AllergySource.openMeteo,
        dustMicrogramsPerCubicMeter: 60,
      );

      expect(data.dustLevel, AllergyLevel.high);
    });

    test('is null when no dust value is available', () {
      final data = AllergyData(
        generatedAt: DateTime.utc(2026, 8, 13, 12),
        location: _dc,
        source: AllergySource.openMeteo,
      );

      expect(data.dustLevel, isNull);
    });
  });

  group('isStaleAsOf', () {
    test('is false just after fetching, true well past the threshold', () {
      final data = AllergyData(
        generatedAt: DateTime.utc(2026, 8, 13, 12),
        location: _dc,
        source: AllergySource.openMeteo,
      );

      expect(data.isStaleAsOf(DateTime.utc(2026, 8, 13, 12, 1)), isFalse);
      expect(data.isStaleAsOf(DateTime.utc(2026, 8, 13, 15)), isTrue);
    });
  });
}
