import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/features/locations/application/locations_controller.dart';
import 'package:weather/features/locations/presentation/locations_screen.dart';

Future<ProviderContainer> _containerWithPrefs() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  return container;
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LocationsScreen()),
    ),
  );
}

/// Opens the add-location flow via the FAB chooser and drills into the
/// Advanced coordinate form — the path exercised by most of these tests,
/// since they're really testing the form/validation, not the chooser.
Future<void> _openAdvancedFormViaFab(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Advanced: Enter Coordinates'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty state offers Use My Location and Search prominently, with manual entry as a fallback', (tester) async {
    final container = await _containerWithPrefs();
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text('Where should we get your weather?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Use My Location'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Search for a Location'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.text('Enter coordinates manually'));
    await tester.pumpAndSettle();

    expect(find.text('Advanced: Enter Coordinates'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add Location'), findsOneWidget);
  });

  group('adding a location via Advanced coordinates', () {
    testWidgets('validates empty name and out-of-range coordinates', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await container.read(locationsControllerProvider.notifier).add(
            name: 'Washington, DC',
            latitude: 38.8894,
            longitude: -77.0352,
          );
      await _pump(tester, container);

      await _openAdvancedFormViaFab(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '999');
      await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '0');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.tap(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.text('Must be between -90.0 and 90.0'), findsOneWidget);
      // The sheet stays open since validation failed.
      expect(find.text('Advanced: Enter Coordinates'), findsOneWidget);
    });

    testWidgets('a valid submission adds the location and closes the sheet', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await container.read(locationsControllerProvider.notifier).add(
            name: 'Washington, DC',
            latitude: 38.8894,
            longitude: -77.0352,
          );
      await _pump(tester, container);

      await _openAdvancedFormViaFab(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Camp Runamuck');
      await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '44.2');
      await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '-71.5');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.tap(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.pumpAndSettle();

      expect(find.text('Advanced: Enter Coordinates'), findsNothing);
      expect(find.text('Camp Runamuck'), findsOneWidget);
      expect(container.read(locationsControllerProvider), hasLength(2));
    });

    testWidgets('a near-duplicate coordinate does not create a second entry, and says so', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await container.read(locationsControllerProvider.notifier).add(
            name: 'Washington, DC',
            latitude: 38.8894,
            longitude: -77.0352,
          );
      await _pump(tester, container);

      await _openAdvancedFormViaFab(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'DC Again');
      // A few hundred meters away — inside the duplicate tolerance.
      await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '38.8900');
      await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '-77.0360');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.tap(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.pumpAndSettle();

      expect(container.read(locationsControllerProvider), hasLength(1));
      expect(find.textContaining('already have a saved location'), findsOneWidget);
    });
  });

  testWidgets('editing a location pre-fills the form and saves the update', (tester) async {
    final container = await _containerWithPrefs();
    addTearDown(container.dispose);
    await container.read(locationsControllerProvider.notifier).add(
          name: 'Washington, DC',
          latitude: 38.8894,
          longitude: -77.0352,
        );
    await _pump(tester, container);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Location'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Name'), findsOneWidget);
    final nameField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Name'));
    expect(nameField.controller!.text, 'Washington, DC');

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'DC Home');
    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('DC Home'), findsOneWidget);
    expect(find.text('Washington, DC'), findsNothing);
    expect(container.read(locationsControllerProvider).single.name, 'DC Home');
  });

  group('deleting a location', () {
    testWidgets('Cancel in the confirmation dialog keeps the location', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await container.read(locationsControllerProvider.notifier).add(
            name: 'Washington, DC',
            latitude: 38.8894,
            longitude: -77.0352,
          );
      await _pump(tester, container);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Washington, DC?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(container.read(locationsControllerProvider), hasLength(1));
      expect(find.text('Washington, DC'), findsOneWidget);
    });

    testWidgets('Delete in the confirmation dialog removes the location', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await container.read(locationsControllerProvider.notifier).add(
            name: 'Washington, DC',
            latitude: 38.8894,
            longitude: -77.0352,
          );
      await _pump(tester, container);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(container.read(locationsControllerProvider), isEmpty);
      expect(find.text('Where should we get your weather?'), findsOneWidget);
    });
  });

  testWidgets('toggling favorite moves the favorite flag off the previous favorite', (tester) async {
    final container = await _containerWithPrefs();
    addTearDown(container.dispose);
    final notifier = container.read(locationsControllerProvider.notifier);
    await notifier.add(name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);
    await notifier.add(name: 'Camp Runamuck', latitude: 44.2, longitude: -71.5);
    await _pump(tester, container);

    var locations = container.read(locationsControllerProvider);
    expect(locations.firstWhere((l) => l.name == 'Washington, DC').isFavorite, isTrue);
    expect(locations.firstWhere((l) => l.name == 'Camp Runamuck').isFavorite, isFalse);

    final favoriteButtons = find.byIcon(Icons.star_border_rounded);
    await tester.tap(favoriteButtons.first);
    await tester.pumpAndSettle();

    locations = container.read(locationsControllerProvider);
    expect(locations.firstWhere((l) => l.name == 'Washington, DC').isFavorite, isFalse);
    expect(locations.firstWhere((l) => l.name == 'Camp Runamuck').isFavorite, isTrue);
  });

  testWidgets('tapping a tile selects that location', (tester) async {
    final container = await _containerWithPrefs();
    addTearDown(container.dispose);
    final notifier = container.read(locationsControllerProvider.notifier);
    await notifier.add(name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);
    await notifier.add(name: 'Camp Runamuck', latitude: 44.2, longitude: -71.5);
    await _pump(tester, container);

    expect(container.read(selectedLocationIdProvider), isNull);

    await tester.tap(find.text('Camp Runamuck'));
    await tester.pump();

    final campId = container.read(locationsControllerProvider).firstWhere((l) => l.name == 'Camp Runamuck').id;
    expect(container.read(selectedLocationIdProvider), campId);
  });
}
