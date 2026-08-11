import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/services/geocoding/nominatim_geocoding_client.dart';
import 'package:weather/features/locations/application/locations_controller.dart';
import 'package:weather/features/locations/presentation/widgets/location_search_sheet.dart';

Future<ProviderContainer> _containerWithSearchResponse({String body = '[]', int status = 200}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final client = NominatimGeocodingClient(httpClient: MockClient((_) async => http.Response(body, status)));
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    geocodingClientProvider.overrideWithValue(client),
  ]);
}

/// Opens the sheet the same way production code does — via
/// `showModalBottomSheet` from a button — rather than pumping it as the
/// only route, so `Navigator.pop()` inside the sheet (on selecting a
/// result) has a real route to close.
Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const LocationSearchSheet(),
                ),
                child: const Text('Open Search'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Search'));
  await tester.pumpAndSettle();
}

const _oneResultBody = '[{"lat": "38.8894", "lon": "-77.0352", "name": "Washington", '
    '"address": {"city": "Washington", "state": "District of Columbia", "country": "United States"}}]';

void main() {
  testWidgets('shows an idle hint before any search is submitted', (tester) async {
    final container = await _containerWithSearchResponse();
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.textContaining('Search for a city'), findsOneWidget);
  });

  testWidgets('submitting a query shows results, and selecting one saves and selects it', (tester) async {
    final container = await _containerWithSearchResponse(body: _oneResultBody);
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.enterText(find.byType(TextField), 'Washington, DC');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Washington'), findsOneWidget);
    expect(find.text('District of Columbia, United States'), findsOneWidget);

    await tester.tap(find.text('Washington'));
    await tester.pumpAndSettle();

    final saved = container.read(locationsControllerProvider);
    expect(saved, hasLength(1));
    expect(saved.single.name, 'Washington');
    expect(saved.single.latitude, 38.8894);
    expect(saved.single.longitude, -77.0352);
    expect(container.read(selectedLocationIdProvider), saved.single.id);
    // The sheet closes on selection.
    expect(find.byType(LocationSearchSheet), findsNothing);
  });

  testWidgets('a search with no results shows a clear "no locations found" message', (tester) async {
    final container = await _containerWithSearchResponse(body: '[]');
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.enterText(find.byType(TextField), 'Nowhereville');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('No locations found for "Nowhereville".'), findsOneWidget);
  });

  testWidgets('a failed search shows an error with a retry action', (tester) async {
    final container = await _containerWithSearchResponse(status: 503);
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.enterText(find.byType(TextField), 'Anywhere');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);

    // Retrying re-runs the same query rather than requiring it to be
    // re-typed; the loading state itself is covered directly (without the
    // flakiness of trying to catch a fast MockClient mid-flight) by
    // location_search_controller_test.dart.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('selecting a duplicate result selects the existing saved location instead of adding a second', (tester) async {
    final container = await _containerWithSearchResponse(body: _oneResultBody);
    addTearDown(container.dispose);
    await container.read(locationsControllerProvider.notifier).add(
          name: 'Home',
          latitude: 38.8894,
          longitude: -77.0352,
        );
    await _pump(tester, container);

    await tester.enterText(find.byType(TextField), 'Washington, DC');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Washington'));
    await tester.pumpAndSettle();

    expect(container.read(locationsControllerProvider), hasLength(1));
    expect(container.read(locationsControllerProvider).single.name, 'Home');
    expect(find.textContaining('already have'), findsOneWidget);
  });
}
