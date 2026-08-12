import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/app/zmanim_settings_controller.dart';
import 'package:weather/core/models/zmanim/hebcal_zman_field.dart';
import 'package:weather/core/models/zmanim/zman_definition.dart';
import 'package:weather/core/models/zmanim/zmanim_configuration.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  });

  tearDown(() => container.dispose());

  group('showZmanimProvider', () {
    test('defaults to true (ON)', () {
      expect(container.read(showZmanimProvider), isTrue);
    });

    test('persists across a fresh container reading the same prefs', () async {
      await container.read(showZmanimProvider.notifier).setShowZmanim(false);
      expect(container.read(showZmanimProvider), isFalse);

      final prefs = await SharedPreferences.getInstance();
      final reloaded = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      expect(reloaded.read(showZmanimProvider), isFalse);
      reloaded.dispose();
    });
  });

  group('ZmanimConfigurationController', () {
    test('defaults to the approved 12', () {
      expect(container.read(zmanimConfigurationProvider), ZmanimConfiguration.defaults());
    });

    test('setEnabled disables and re-enables a single row without affecting others', () async {
      final notifier = container.read(zmanimConfigurationProvider.notifier);

      await notifier.setEnabled('netz', false);
      var config = container.read(zmanimConfigurationProvider);
      expect(config.definitions.firstWhere((d) => d.id == 'netz').enabled, isFalse);
      expect(config.definitions.where((d) => d.enabled), hasLength(11));

      await notifier.setEnabled('netz', true);
      config = container.read(zmanimConfigurationProvider);
      expect(config.definitions.firstWhere((d) => d.id == 'netz').enabled, isTrue);
    });

    test('reorder moves a definition without dropping or duplicating any row', () async {
      final notifier = container.read(zmanimConfigurationProvider.notifier);

      await notifier.reorder(2, 0); // move Netz (index 2) to the front

      final ids = container.read(zmanimConfigurationProvider).definitions.map((d) => d.id).toList();
      expect(ids.first, 'netz');
      expect(ids.toSet(), hasLength(12));
    });

    test('setField changes which Hebcal calculation backs a row', () async {
      final notifier = container.read(zmanimConfigurationProvider.notifier);

      await notifier.setField('tzeis', HebcalZmanField.tzeit72min);

      final tzeis = container.read(zmanimConfigurationProvider).definitions.firstWhere((d) => d.id == 'tzeis');
      expect(tzeis.field, HebcalZmanField.tzeit72min);
    });

    test('setDisplayName renames a row without changing its id or field', () async {
      final notifier = container.read(zmanimConfigurationProvider.notifier);

      await notifier.setDisplayName('chatzos', 'Midday');

      final def = container.read(zmanimConfigurationProvider).definitions.firstWhere((d) => d.id == 'chatzos');
      expect(def.displayName, 'Midday');
      expect(def.field, HebcalZmanField.chatzot);
    });

    test('setDisplayName ignores a blank name', () async {
      final notifier = container.read(zmanimConfigurationProvider.notifier);

      await notifier.setDisplayName('chatzos', '   ');

      final def = container.read(zmanimConfigurationProvider).definitions.firstWhere((d) => d.id == 'chatzos');
      expect(def.displayName, 'Chatzos');
    });

    test('addDefinition appends a new row from the additional-Zmanim pool', () async {
      final notifier = container.read(zmanimConfigurationProvider.notifier);
      final template = additionalZmanTemplates.firstWhere((d) => d.id == 'tzeis_72min');

      await notifier.addDefinition(template);

      final config = container.read(zmanimConfigurationProvider);
      expect(config.definitions, hasLength(13));
      expect(config.definitions.last.id, 'tzeis_72min');
    });

    test('addDefinition ignores a duplicate id', () async {
      final notifier = container.read(zmanimConfigurationProvider.notifier);
      const duplicate = ZmanDefinition(id: 'netz', displayName: 'Netz again', field: HebcalZmanField.sunrise);

      await notifier.addDefinition(duplicate);

      expect(container.read(zmanimConfigurationProvider).definitions, hasLength(12));
    });

    test('removeDefinition deletes a row entirely', () async {
      final notifier = container.read(zmanimConfigurationProvider.notifier);

      await notifier.removeDefinition('netz');

      final config = container.read(zmanimConfigurationProvider);
      expect(config.definitions, hasLength(11));
      expect(config.definitions.any((d) => d.id == 'netz'), isFalse);
    });

    test('persists across a fresh container reading the same prefs', () async {
      await container.read(zmanimConfigurationProvider.notifier).setEnabled('netz', false);

      final prefs = await SharedPreferences.getInstance();
      final reloaded = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      final reloadedConfig = reloaded.read(zmanimConfigurationProvider);
      expect(reloadedConfig.definitions.firstWhere((d) => d.id == 'netz').enabled, isFalse);
      reloaded.dispose();
    });
  });
}
