import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/features/locations/application/locations_controller.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
}

void main() {
  group('add', () {
    test('the first location added is automatically favorited', () async {
      final container = await _container();
      addTearDown(container.dispose);
      final notifier = container.read(locationsControllerProvider.notifier);

      await notifier.add(name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);

      expect(container.read(locationsControllerProvider).single.isFavorite, isTrue);
    });

    test('a second location is not favorited unless explicitly requested', () async {
      final container = await _container();
      addTearDown(container.dispose);
      final notifier = container.read(locationsControllerProvider.notifier);

      await notifier.add(name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);
      await notifier.add(name: 'Camp Runamuck', latitude: 44.2, longitude: -71.5);

      final locations = container.read(locationsControllerProvider);
      expect(locations.firstWhere((l) => l.name == 'Washington, DC').isFavorite, isTrue);
      expect(locations.firstWhere((l) => l.name == 'Camp Runamuck').isFavorite, isFalse);
    });

    test('persists across a fresh controller reading the same storage', () async {
      final container = await _container();
      addTearDown(container.dispose);
      await container.read(locationsControllerProvider.notifier).add(
            name: 'Washington, DC',
            latitude: 38.8894,
            longitude: -77.0352,
          );

      container.invalidate(locationsControllerProvider);

      expect(container.read(locationsControllerProvider).single.name, 'Washington, DC');
    });
  });

  test('update replaces the matching location and leaves others untouched', () async {
    final container = await _container();
    addTearDown(container.dispose);
    final notifier = container.read(locationsControllerProvider.notifier);
    await notifier.add(name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);
    await notifier.add(name: 'Camp Runamuck', latitude: 44.2, longitude: -71.5);

    final dc = container.read(locationsControllerProvider).firstWhere((l) => l.name == 'Washington, DC');
    await notifier.update(dc.copyWith(name: 'DC Home'));

    final locations = container.read(locationsControllerProvider);
    expect(locations.map((l) => l.name), containsAll(['DC Home', 'Camp Runamuck']));
    expect(locations, hasLength(2));
  });

  group('remove', () {
    test('removing a non-favorite location leaves the favorite unchanged', () async {
      final container = await _container();
      addTearDown(container.dispose);
      final notifier = container.read(locationsControllerProvider.notifier);
      await notifier.add(name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);
      await notifier.add(name: 'Camp Runamuck', latitude: 44.2, longitude: -71.5);
      final camp = container.read(locationsControllerProvider).firstWhere((l) => l.name == 'Camp Runamuck');

      await notifier.remove(camp.id);

      final locations = container.read(locationsControllerProvider);
      expect(locations, hasLength(1));
      expect(locations.single.isFavorite, isTrue);
    });

    test('removing the favorite promotes another location to favorite', () async {
      final container = await _container();
      addTearDown(container.dispose);
      final notifier = container.read(locationsControllerProvider.notifier);
      await notifier.add(name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);
      await notifier.add(name: 'Camp Runamuck', latitude: 44.2, longitude: -71.5);
      final dc = container.read(locationsControllerProvider).firstWhere((l) => l.name == 'Washington, DC');

      await notifier.remove(dc.id);

      final locations = container.read(locationsControllerProvider);
      expect(locations, hasLength(1));
      expect(locations.single.name, 'Camp Runamuck');
      expect(locations.single.isFavorite, isTrue);
    });

    test('removing the only location leaves an empty list without throwing', () async {
      final container = await _container();
      addTearDown(container.dispose);
      final notifier = container.read(locationsControllerProvider.notifier);
      await notifier.add(name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);
      final dc = container.read(locationsControllerProvider).single;

      await notifier.remove(dc.id);

      expect(container.read(locationsControllerProvider), isEmpty);
    });
  });

  test('setFavorite moves the favorite flag so exactly one location holds it', () async {
    final container = await _container();
    addTearDown(container.dispose);
    final notifier = container.read(locationsControllerProvider.notifier);
    await notifier.add(name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);
    await notifier.add(name: 'Camp Runamuck', latitude: 44.2, longitude: -71.5);
    final camp = container.read(locationsControllerProvider).firstWhere((l) => l.name == 'Camp Runamuck');

    await notifier.setFavorite(camp.id);

    final locations = container.read(locationsControllerProvider);
    expect(locations.where((l) => l.isFavorite), hasLength(1));
    expect(locations.firstWhere((l) => l.isFavorite).name, 'Camp Runamuck');
  });

  group('selectedLocationProvider', () {
    test('resolves to the favorite when no explicit selection has been made', () async {
      final container = await _container();
      addTearDown(container.dispose);
      final notifier = container.read(locationsControllerProvider.notifier);
      await notifier.add(name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);
      await notifier.add(name: 'Camp Runamuck', latitude: 44.2, longitude: -71.5);

      expect(container.read(selectedLocationProvider)?.name, 'Washington, DC');
    });

    test('resolves to the explicitly selected location once one is set', () async {
      final container = await _container();
      addTearDown(container.dispose);
      final notifier = container.read(locationsControllerProvider.notifier);
      await notifier.add(name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);
      await notifier.add(name: 'Camp Runamuck', latitude: 44.2, longitude: -71.5);
      final camp = container.read(locationsControllerProvider).firstWhere((l) => l.name == 'Camp Runamuck');

      container.read(selectedLocationIdProvider.notifier).state = camp.id;

      expect(container.read(selectedLocationProvider)?.name, 'Camp Runamuck');
    });

    test('falls back to the favorite when the selected id no longer exists', () async {
      final container = await _container();
      addTearDown(container.dispose);
      final notifier = container.read(locationsControllerProvider.notifier);
      await notifier.add(name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);
      container.read(selectedLocationIdProvider.notifier).state = 'stale-id-that-was-removed';

      expect(container.read(selectedLocationProvider)?.name, 'Washington, DC');
    });

    test('is null when there are no saved locations', () async {
      final container = await _container();
      addTearDown(container.dispose);

      expect(container.read(selectedLocationProvider), isNull);
    });
  });
}
