import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/zmanim/hebcal_zman_field.dart';
import 'package:weather/core/models/zmanim/zman_definition.dart';

void main() {
  group('ZmanDefinition', () {
    test('round-trips through toJson/tryFromJson', () {
      const def = ZmanDefinition(id: 'alos', displayName: 'Alos', field: HebcalZmanField.alotHaShachar, enabled: false);

      final roundTripped = ZmanDefinition.tryFromJson(def.toJson());

      expect(roundTripped, def);
    });

    test('copyWith changes only the given fields', () {
      const def = ZmanDefinition(id: 'alos', displayName: 'Alos', field: HebcalZmanField.alotHaShachar);

      final renamed = def.copyWith(displayName: 'Dawn');

      expect(renamed.id, 'alos');
      expect(renamed.displayName, 'Dawn');
      expect(renamed.field, HebcalZmanField.alotHaShachar);
      expect(renamed.enabled, isTrue);
    });

    test('enabled defaults to true when omitted from JSON (pre-migration data)', () {
      final def = ZmanDefinition.tryFromJson({
        'id': 'alos',
        'displayName': 'Alos',
        'field': 'alotHaShachar',
      });

      expect(def!.enabled, isTrue);
    });

    test('returns null for an unrecognized Hebcal field', () {
      final def = ZmanDefinition.tryFromJson({
        'id': 'alos',
        'displayName': 'Alos',
        'field': 'notARealField',
      });

      expect(def, isNull);
    });

    test('returns null when required fields are missing', () {
      expect(ZmanDefinition.tryFromJson({'displayName': 'Alos', 'field': 'alotHaShachar'}), isNull);
      expect(ZmanDefinition.tryFromJson({'id': 'alos', 'field': 'alotHaShachar'}), isNull);
    });
  });
}
