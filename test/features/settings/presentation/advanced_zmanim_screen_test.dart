import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/app/zmanim_settings_controller.dart';
import 'package:weather/core/models/zmanim/hebcal_zman_field.dart';
import 'package:weather/core/models/zmanim/zmanim_configuration.dart';
import 'package:weather/features/settings/presentation/advanced_zmanim_screen.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  // The default test surface (800 logical px tall) isn't tall enough to
  // render all 12+ rows without scrolling, and ListView only mounts
  // elements near the viewport -- widen the surface instead of scrolling
  // to each row individually in every test below.
  tester.view.physicalSize = const Size(400, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: AdvancedZmanimScreen()),
    ),
  );
}

void main() {
  testWidgets('renders the default 12 in order', (tester) async {
    final container = await _container();
    await _pump(tester, container);

    expect(find.text('Alos'), findsOneWidget);
    expect(find.text('Tzeis'), findsOneWidget);

    final alosPos = tester.getTopLeft(find.text('Alos')).dy;
    final tzeisPos = tester.getTopLeft(find.text('Tzeis')).dy;
    expect(alosPos, lessThan(tzeisPos));

    container.dispose();
  });

  testWidgets('toggling a switch disables the row in the underlying configuration', (tester) async {
    final container = await _container();
    await _pump(tester, container);

    final netzRow = find.ancestor(of: find.text('Netz'), matching: find.byType(Card));
    await tester.tap(find.descendant(of: netzRow, matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    final config = container.read(zmanimConfigurationProvider);
    expect(config.definitions.firstWhere((d) => d.id == 'netz').enabled, isFalse);

    container.dispose();
  });

  testWidgets('moving a row down changes its order', (tester) async {
    final container = await _container();
    await _pump(tester, container);

    final alosRow = find.ancestor(of: find.text('Alos'), matching: find.byType(Card));
    final downButton = find.descendant(of: alosRow, matching: find.byTooltip('Move down'));
    await tester.tap(downButton);
    await tester.pumpAndSettle();

    final ids = container.read(zmanimConfigurationProvider).definitions.map((d) => d.id).toList();
    expect(ids[1], 'alos');
    expect(ids[0], 'earliest_tallis_tefillin');

    container.dispose();
  });

  testWidgets('renaming a row through the dialog updates its display name', (tester) async {
    final container = await _container();
    await _pump(tester, container);

    await tester.tap(find.text('Chatzos'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Midday');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Midday'), findsOneWidget);
    expect(find.text('Chatzos'), findsNothing);
    final config = container.read(zmanimConfigurationProvider);
    expect(config.definitions.firstWhere((d) => d.id == 'chatzos').displayName, 'Midday');

    container.dispose();
  });

  testWidgets('a row with real calculation alternatives shows a dropdown; a row without one does not', (tester) async {
    final container = await _container();
    await _pump(tester, container);

    // Tzeis has real alternatives (tzeit7083deg/85deg/42min/50min/72min).
    expect(find.byType(DropdownButton<HebcalZmanField>), findsWidgets);

    // Chatzos has no real alternative -- just a static calculation label.
    final chatzosRow = find.ancestor(of: find.text('Chatzos'), matching: find.byType(Card));
    expect(find.descendant(of: chatzosRow, matching: find.byType(DropdownButton<HebcalZmanField>)), findsNothing);
    expect(find.descendant(of: chatzosRow, matching: find.textContaining('Calculation:')), findsOneWidget);

    container.dispose();
  });

  testWidgets('removing a row deletes it from the configuration', (tester) async {
    final container = await _container();
    await _pump(tester, container);

    final netzRow = find.ancestor(of: find.text('Netz'), matching: find.byType(Card));
    await tester.tap(find.descendant(of: netzRow, matching: find.byTooltip('Remove')));
    await tester.pumpAndSettle();

    expect(find.text('Netz'), findsNothing);
    expect(container.read(zmanimConfigurationProvider).definitions, hasLength(11));

    container.dispose();
  });

  testWidgets('adding a Zman from the picker appends it to the configuration', (tester) async {
    final container = await _container();
    await _pump(tester, container);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Add a Zman'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tzeis (72 Minutes, Rabbeinu Tam)'));
    await tester.pumpAndSettle();

    final config = container.read(zmanimConfigurationProvider);
    expect(config.definitions, hasLength(13));
    expect(config.definitions.last.id, 'tzeis_72min');

    container.dispose();
  });

  testWidgets('reset to defaults restores the approved 12 after a change', (tester) async {
    final container = await _container();
    await container.read(zmanimConfigurationProvider.notifier).setEnabled('netz', false);
    await _pump(tester, container);

    await tester.tap(find.byTooltip('Reset to defaults'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(container.read(zmanimConfigurationProvider), ZmanimConfiguration.defaults());

    container.dispose();
  });
}
