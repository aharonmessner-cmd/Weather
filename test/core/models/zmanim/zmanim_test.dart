import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/models/zmanim/hebcal_zman_field.dart';
import 'package:weather/core/models/zmanim/zmanim.dart';

const _dc = Location(id: 'dc', name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);

void main() {
  group('Zmanim JSON round trip', () {
    test('round-trips locationDate, location, generatedAt, and times', () {
      final data = Zmanim(
        locationDate: '2026-08-11',
        location: _dc,
        generatedAt: DateTime.parse('2026-08-11T04:00:00-04:00'),
        times: {
          HebcalZmanField.sunrise: DateTime.parse('2026-08-11T06:08:00-04:00'),
          HebcalZmanField.sunset: DateTime.parse('2026-08-11T19:58:00-04:00'),
        },
      );

      final roundTripped = Zmanim.tryFromJson(data.toJson());

      expect(roundTripped, data);
    });

    test('returns null for malformed JSON', () {
      expect(Zmanim.tryFromJson({'locationDate': '2026-08-11'}), isNull);
      expect(Zmanim.tryFromJson({}), isNull);
    });

    test('returns null when "times" ends up empty after filtering unrecognized fields', () {
      final json = {
        'locationDate': '2026-08-11',
        'location': _dc.toJson(),
        'generatedAt': DateTime.parse('2026-08-11T04:00:00-04:00').toIso8601String(),
        'times': {'notARealField': '2026-08-11T06:08:00-04:00'},
      };

      expect(Zmanim.tryFromJson(json), isNull);
    });
  });
}
