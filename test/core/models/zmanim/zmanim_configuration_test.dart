import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/zmanim/zman_calculation_groups.dart';
import 'package:weather/core/models/zmanim/hebcal_zman_field.dart';
import 'package:weather/core/models/zmanim/zmanim_configuration.dart';

void main() {
  group('default Zmanim configuration', () {
    test('contains exactly the 12 approved Zmanim in the exact required order', () {
      final names = ZmanimConfiguration.defaults().definitions.map((d) => d.displayName).toList();

      expect(names, [
        'Alos',
        'Earliest Tallis and Tefillin',
        'Netz',
        'Sof Zman Krias Shema MG"A',
        'Sof Zman Krias Shema GRA',
        'Sof Zman Tefilla',
        'Chatzos',
        'Mincha Gedola',
        'Mincha Ketana',
        'Plag HaMincha',
        'Shkia',
        'Tzeis',
      ]);
    });

    test('every default definition is enabled and has a unique id', () {
      final defs = ZmanimConfiguration.defaults().definitions;
      expect(defs.every((d) => d.enabled), isTrue);
      expect(defs.map((d) => d.id).toSet(), hasLength(defs.length));
    });

    test('every default definition maps to a real, distinct Hebcal field', () {
      final fields = ZmanimConfiguration.defaults().definitions.map((d) => d.field).toSet();
      expect(fields, hasLength(12));
    });
  });

  group('additionalZmanTemplates', () {
    test('has unique ids, none overlapping the defaults', () {
      final defaultIds = ZmanimConfiguration.defaults().definitions.map((d) => d.id).toSet();
      final templateIds = additionalZmanTemplates.map((d) => d.id).toSet();

      expect(templateIds, hasLength(additionalZmanTemplates.length));
      expect(defaultIds.intersection(templateIds), isEmpty);
    });

    test('covers every Hebcal field not already used by a default definition', () {
      final defaultFields = ZmanimConfiguration.defaults().definitions.map((d) => d.field).toSet();
      final templateFields = additionalZmanTemplates.map((d) => d.field).toSet();

      expect(defaultFields.union(templateFields), HebcalZmanField.values.toSet());
    });
  });

  group('ZmanimConfiguration JSON round trip', () {
    test('round-trips a custom configuration', () {
      final config = ZmanimConfiguration.defaults();

      final roundTripped = ZmanimConfiguration.tryFromJson(config.toJson());

      expect(roundTripped, config);
    });

    test('falls back to defaults for malformed JSON rather than crashing', () {
      expect(ZmanimConfiguration.tryFromJson({'definitions': 'not a list'}), ZmanimConfiguration.defaults());
      expect(ZmanimConfiguration.tryFromJson({}), ZmanimConfiguration.defaults());
    });

    test('falls back to defaults when every definition entry is malformed', () {
      final result = ZmanimConfiguration.tryFromJson({
        'definitions': [
          {'id': 'x'},
        ],
      });
      expect(result, ZmanimConfiguration.defaults());
    });
  });

  group('alternativesFor (calculation groups)', () {
    test('returns the full opinion group for a grouped field', () {
      final alternatives = alternativesFor(HebcalZmanField.sofZmanShmaMGA);
      expect(alternatives, contains(HebcalZmanField.sofZmanShma));
      expect(alternatives, contains(HebcalZmanField.sofZmanShmaMGA));
      expect(alternatives, contains(HebcalZmanField.sofZmanShmaBaalHatanya));
    });

    test('returns just the field itself when there is no real halachic alternative', () {
      expect(alternativesFor(HebcalZmanField.chatzot), [HebcalZmanField.chatzot]);
    });

    test('every group contains only unique fields across the whole table', () {
      final seen = <HebcalZmanField>{};
      for (final group in zmanCalculationGroups) {
        for (final field in group) {
          expect(seen.contains(field), isFalse, reason: '$field appears in more than one calculation group');
          seen.add(field);
        }
      }
    });
  });
}
