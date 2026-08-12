import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/zmanim/hebcal_zman_field.dart';
import 'package:weather/core/models/zmanim/hebcal_zmanim_response.dart';

void main() {
  group('HebcalZmanimResponse.tryParse', () {
    test('parses recognized fields into HebcalZmanField keys', () {
      final json = {
        'times': {
          'alotHaShachar': '2026-08-11T05:01:00-04:00',
          'sunrise': '2026-08-11T06:08:00-04:00',
          'chatzot': '2026-08-11T13:03:00-04:00',
        },
      };

      final response = HebcalZmanimResponse.tryParse(json);

      expect(response, isNotNull);
      expect(response!.times[HebcalZmanField.alotHaShachar], DateTime.parse('2026-08-11T05:01:00-04:00'));
      expect(response.times[HebcalZmanField.sunrise], DateTime.parse('2026-08-11T06:08:00-04:00'));
      expect(response.times[HebcalZmanField.chatzot], DateTime.parse('2026-08-11T13:03:00-04:00'));
      expect(response.times, hasLength(3));
    });

    test('silently skips a field Hebcal returns that this app does not recognize', () {
      final json = {
        'times': {
          'sunrise': '2026-08-11T06:08:00-04:00',
          'someBrandNewZmanHebcalAddsLater': '2026-08-11T07:00:00-04:00',
        },
      };

      final response = HebcalZmanimResponse.tryParse(json);

      expect(response, isNotNull);
      expect(response!.times, hasLength(1));
      expect(response.times.containsKey(HebcalZmanField.sunrise), isTrue);
    });

    test('skips a field with a non-string or unparsable value', () {
      final json = {
        'times': {
          'sunrise': '2026-08-11T06:08:00-04:00',
          'chatzot': 12345,
          'sunset': 'not-a-date',
        },
      };

      final response = HebcalZmanimResponse.tryParse(json);

      expect(response!.times, hasLength(1));
    });

    test('returns null when "times" is missing', () {
      expect(HebcalZmanimResponse.tryParse({'date': '2026-08-11'}), isNull);
    });

    test('returns null when "times" is not a map', () {
      expect(HebcalZmanimResponse.tryParse({'times': 'nope'}), isNull);
    });

    test('returns null when every entry in "times" is unrecognized or unparsable', () {
      expect(
        HebcalZmanimResponse.tryParse({
          'times': {'unknownField': 'also not real'},
        }),
        isNull,
      );
    });
  });

  group('HebcalZmanField.tryParse', () {
    test('matches every known Hebcal API key', () {
      expect(HebcalZmanField.tryParse('sofZmanShmaMGA'), HebcalZmanField.sofZmanShmaMGA);
      expect(HebcalZmanField.tryParse('tzeit7083deg'), HebcalZmanField.tzeit7083deg);
      expect(HebcalZmanField.tryParse('plagHaMincha'), HebcalZmanField.plagHaMincha);
    });

    test('returns null for an unrecognized key or null input', () {
      expect(HebcalZmanField.tryParse('notAZman'), isNull);
      expect(HebcalZmanField.tryParse(null), isNull);
    });
  });
}
