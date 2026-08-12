import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/models/zmanim/hebcal_zman_field.dart';
import 'package:weather/core/models/zmanim/zman_definition.dart';
import 'package:weather/core/models/zmanim/zman_selection.dart';
import 'package:weather/core/models/zmanim/zmanim.dart';
import 'package:weather/core/models/zmanim/zmanim_configuration.dart';

const _dc = Location(id: 'dc', name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);

// A representative day's worth of times for the default 12, all in
// America/New_York (EDT, -04:00) -- mirrors the exact example times in
// the feature request.
final _times = <HebcalZmanField, DateTime>{
  HebcalZmanField.alotHaShachar: DateTime.parse('2026-08-11T05:01:00-04:00'), // Alos
  HebcalZmanField.misheyakir: DateTime.parse('2026-08-11T05:29:00-04:00'), // Earliest Tallis/Tefillin
  HebcalZmanField.sunrise: DateTime.parse('2026-08-11T06:08:00-04:00'), // Netz
  HebcalZmanField.sofZmanShmaMGA: DateTime.parse('2026-08-11T09:12:00-04:00'), // Sof Zman Shema MGA
  HebcalZmanField.sofZmanShma: DateTime.parse('2026-08-11T09:48:00-04:00'), // Sof Zman Shema GRA
  HebcalZmanField.sofZmanTfilla: DateTime.parse('2026-08-11T10:53:00-04:00'), // Sof Zman Tefilla
  HebcalZmanField.chatzot: DateTime.parse('2026-08-11T13:03:00-04:00'), // Chatzos
  HebcalZmanField.minchaGedola: DateTime.parse('2026-08-11T13:36:00-04:00'), // Mincha Gedola
  HebcalZmanField.minchaKetana: DateTime.parse('2026-08-11T17:07:00-04:00'), // Mincha Ketana
  HebcalZmanField.plagHaMincha: DateTime.parse('2026-08-11T18:52:00-04:00'), // Plag HaMincha
  HebcalZmanField.sunset: DateTime.parse('2026-08-11T19:58:00-04:00'), // Shkia
  HebcalZmanField.tzeit7083deg: DateTime.parse('2026-08-11T20:26:00-04:00'), // Tzeis
};

Zmanim _snapshot() {
  return Zmanim(
    locationDate: '2026-08-11',
    location: _dc,
    generatedAt: DateTime.parse('2026-08-11T04:00:00-04:00'),
    times: _times,
  );
}

void main() {
  group('selectZmanim', () {
    test('produces the 12 default Zmanim in configuration order with the right times', () {
      final result = selectZmanim(_snapshot(), ZmanimConfiguration.defaults());

      expect(result.map((z) => z.displayName), [
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
      expect(result[2].time, DateTime.parse('2026-08-11T06:08:00-04:00'));
    });

    test('skips disabled definitions', () {
      final config = ZmanimConfiguration(
        definitions: ZmanimConfiguration.defaults().definitions.map((d) {
          return d.id == 'netz' ? d.copyWith(enabled: false) : d;
        }).toList(),
      );

      final result = selectZmanim(_snapshot(), config);

      expect(result.map((z) => z.id), isNot(contains('netz')));
      expect(result, hasLength(11));
    });

    test('reordering the configuration reorders the result', () {
      final defs = List.of(ZmanimConfiguration.defaults().definitions);
      final netz = defs.removeAt(2);
      defs.insert(0, netz);
      final result = selectZmanim(_snapshot(), ZmanimConfiguration(definitions: defs));

      expect(result.first.id, 'netz');
    });

    test('a definition whose field is missing from the data is silently omitted', () {
      final config = ZmanimConfiguration(definitions: [
        const ZmanDefinition(id: 'netz', displayName: 'Netz', field: HebcalZmanField.sunrise),
        const ZmanDefinition(id: 'dusk', displayName: 'Dusk', field: HebcalZmanField.dusk), // not in _times
      ]);

      final result = selectZmanim(_snapshot(), config);

      expect(result, hasLength(1));
      expect(result.single.id, 'netz');
    });

    test('an edited display name and swapped calculation field both take effect', () {
      final config = ZmanimConfiguration(definitions: [
        const ZmanDefinition(id: 'shema', displayName: 'Kriat Shema (custom)', field: HebcalZmanField.sofZmanShma),
      ]);

      final result = selectZmanim(_snapshot(), config);

      expect(result.single.displayName, 'Kriat Shema (custom)');
      expect(result.single.time, DateTime.parse('2026-08-11T09:48:00-04:00'));
    });
  });

  group('remainingZmanim: only-today filtering', () {
    final allSelected = selectZmanim(_snapshot(), ZmanimConfiguration.defaults());

    test('before Alos: every configured zman is shown', () {
      final now = DateTime.parse('2026-08-11T04:30:00-04:00');
      expect(remainingZmanim(allSelected, now).map((z) => z.displayName), allSelected.map((z) => z.displayName));
    });

    test('after Alos: Alos disappears, everything else remains', () {
      final now = DateTime.parse('2026-08-11T05:15:00-04:00');
      final result = remainingZmanim(allSelected, now);
      expect(result.map((z) => z.displayName), isNot(contains('Alos')));
      expect(result, hasLength(11));
    });

    test('after Netz: Alos, Tallis/Tefillin, and Netz all disappear', () {
      final now = DateTime.parse('2026-08-11T06:30:00-04:00');
      final result = remainingZmanim(allSelected, now);
      expect(result.map((z) => z.displayName), isNot(contains('Alos')));
      expect(result.map((z) => z.displayName), isNot(contains('Earliest Tallis and Tefillin')));
      expect(result.map((z) => z.displayName), isNot(contains('Netz')));
      expect(result.first.displayName, 'Sof Zman Krias Shema MG"A');
    });

    test('the exact example: 8:30 AM shows Sof Zman Krias Shema MG"A first, nothing earlier', () {
      final now = DateTime.parse('2026-08-11T08:30:00-04:00');
      final result = remainingZmanim(allSelected, now);
      expect(result.first.displayName, 'Sof Zman Krias Shema MG"A');
      expect(result.map((z) => z.displayName), isNot(contains('Netz')));
    });

    test('after Sof Zman Krias Shema MG"A: that row disappears, GRA row remains', () {
      final now = DateTime.parse('2026-08-11T09:20:00-04:00');
      final result = remainingZmanim(allSelected, now);
      expect(result.map((z) => z.displayName), isNot(contains('Sof Zman Krias Shema MG"A')));
      expect(result.map((z) => z.displayName), contains('Sof Zman Krias Shema GRA'));
    });

    test('after Shkia but before Tzeis: only Tzeis remains', () {
      final now = DateTime.parse('2026-08-11T20:00:00-04:00');
      final result = remainingZmanim(allSelected, now);
      expect(result.map((z) => z.displayName), ['Tzeis']);
    });

    test('after Tzeis: nothing remains', () {
      final now = DateTime.parse('2026-08-11T21:00:00-04:00');
      expect(remainingZmanim(allSelected, now), isEmpty);
    });

    test('a zman exactly at "now" counts as already passed (documented, isAfter is strict)', () {
      final now = DateTime.parse('2026-08-11T06:08:00-04:00'); // exactly Netz
      final result = remainingZmanim(allSelected, now);
      expect(result.map((z) => z.displayName), isNot(contains('Netz')));
    });
  });
}
