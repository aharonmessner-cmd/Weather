import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/features/locations/application/locations_controller.dart';
import 'package:weather/features/locations/presentation/widgets/location_editor_sheet.dart';

Future<ProviderContainer> _containerWithPrefs() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
}

Future<void> _pump(WidgetTester tester, ProviderContainer container, {Location? existing}) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Scaffold(body: LocationEditorSheet(existing: existing))),
    ),
  );
}

void main() {
  group('coordinate keyboard/input behavior', () {
    testWidgets('the coordinate fields use a plain text keyboard, not a signed-decimal numeric pad', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await _pump(tester, container);

      final latField = tester.widget<TextField>(find.widgetWithText(TextField, 'Latitude'));
      final lonField = tester.widget<TextField>(find.widgetWithText(TextField, 'Longitude'));

      // TextInputType.text always has a minus key available; several
      // Android IMEs ignore numberWithOptions(signed: true) and never show
      // one at all, which made negative longitudes hard to enter.
      expect(latField.keyboardType, TextInputType.text);
      expect(lonField.keyboardType, TextInputType.text);
    });

    testWidgets('typing a negative longitude is preserved end to end', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await _pump(tester, container);

      await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '-77.0352');

      final lonField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Longitude'));
      expect(lonField.controller!.text, '-77.0352');
    });

    testWidgets('the input formatter strips anything that is not a digit, minus, or decimal point', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await _pump(tester, container);

      final lonFieldFinder = find.widgetWithText(TextField, 'Longitude');
      final formatters = tester.widget<TextField>(lonFieldFinder).inputFormatters!;
      final formatter = formatters.single as FilteringTextInputFormatter;

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(text: 'ab-77.0c3d52ef');
      final formatted = formatter.formatEditUpdate(oldValue, newValue);

      expect(formatted.text, '-77.0352');
    });
  });

  group('validation', () {
    testWidgets('rejects an out-of-range latitude', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await _pump(tester, container);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Somewhere');
      await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '95');
      await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '-77');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.tap(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.pumpAndSettle();

      expect(find.text('Must be between -90.0 and 90.0'), findsOneWidget);
      expect(container.read(locationsControllerProvider), isEmpty);
    });

    testWidgets('rejects an out-of-range longitude', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await _pump(tester, container);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Somewhere');
      await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '38.8');
      await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '190');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.tap(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.pumpAndSettle();

      expect(find.text('Must be between -180.0 and 180.0'), findsOneWidget);
      expect(container.read(locationsControllerProvider), isEmpty);
    });

    testWidgets('rejects non-numeric coordinate input', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await _pump(tester, container);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Somewhere');
      // The formatter only lets digits/minus/dot through, so simulate a
      // string that's syntactically a lone "-" (survives the formatter
      // but doesn't parse as a number).
      await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '-');
      await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '-77');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.tap(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a number'), findsOneWidget);
    });

    testWidgets('rejects empty coordinate input', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await _pump(tester, container);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Somewhere');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.tap(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsNWidgets(2));
    });

    testWidgets('a valid manual entry saves successfully', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await _pump(tester, container);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Camp Runamuck');
      await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '44.2');
      await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '-71.5');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.tap(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.pumpAndSettle();

      final saved = container.read(locationsControllerProvider);
      expect(saved, hasLength(1));
      expect(saved.single.name, 'Camp Runamuck');
      expect(saved.single.latitude, 44.2);
      expect(saved.single.longitude, -71.5);
    });
  });

  group('duplicate detection', () {
    testWidgets('an exact-duplicate coordinate does not create a second location', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await container.read(locationsControllerProvider.notifier).add(
            name: 'Washington, DC',
            latitude: 38.8894,
            longitude: -77.0352,
          );
      await _pump(tester, container);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'DC Again');
      await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '38.8894');
      await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '-77.0352');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.tap(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.pumpAndSettle();

      expect(container.read(locationsControllerProvider), hasLength(1));
      expect(container.read(locationsControllerProvider).single.name, 'Washington, DC');
    });

    testWidgets('a near-duplicate (within tolerance) coordinate does not create a second location', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await container.read(locationsControllerProvider.notifier).add(
            name: 'Washington, DC',
            latitude: 38.8894,
            longitude: -77.0352,
          );
      await _pump(tester, container);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'DC Again');
      // ~95m away — inside the 1km duplicate tolerance.
      await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '38.8900');
      await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '-77.0360');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.tap(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.pumpAndSettle();

      expect(container.read(locationsControllerProvider), hasLength(1));
    });

    testWidgets('a coordinate far enough away is not treated as a duplicate', (tester) async {
      final container = await _containerWithPrefs();
      addTearDown(container.dispose);
      await container.read(locationsControllerProvider.notifier).add(
            name: 'Washington, DC',
            latitude: 38.8894,
            longitude: -77.0352,
          );
      await _pump(tester, container);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Camp Runamuck');
      await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '44.2');
      await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '-71.5');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.tap(find.widgetWithText(FilledButton, 'Add Location'));
      await tester.pumpAndSettle();

      expect(container.read(locationsControllerProvider), hasLength(2));
    });
  });
}
