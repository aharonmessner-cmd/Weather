import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/app.dart';
import 'package:weather/app/navigation/app_bottom_nav_bar.dart';
import 'package:weather/app/navigation/app_nav_rail.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/models/allergy/allergy_data.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/repositories/allergy_repository.dart';
import 'package:weather/core/services/nws/nws_api_client.dart';

/// Keeps these app-level tests off the network for Allergy data (see the
/// matching double in app_shell_test.dart) -- unlike MinuteCast,
/// Open-Meteo needs no API key, so nothing else here would stop a real
/// HTTP attempt if a location's weather ever loads successfully.
class _NoopAllergyRepository implements AllergyRepository {
  @override
  Future<AllergyData?> getCached(Location location) async => null;

  @override
  Future<AllergyData> fetchAndCache(Location location) => Future.error(StateError('not used in this test'));
}

void main() {
  // Widget tests exercise navigation and local state, not live NWS
  // integration — the API client is overridden so no test ever makes a
  // real network request.
  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final offlineClient = NwsApiClient(
      httpClient: MockClient((_) async => http.Response('offline', 503)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nwsApiClientProvider.overrideWithValue(offlineClient),
          allergyRepositoryProvider.overrideWithValue(_NoopAllergyRepository()),
        ],
        child: const WeatherApp(),
      ),
    );
    await tester.pump();
  }

  testWidgets('app boots to the Weather tab with the empty-locations state', (tester) async {
    await pumpApp(tester);

    expect(find.text('No Locations Yet'), findsOneWidget);
    expect(find.text('Go to Locations'), findsOneWidget);
  });

  testWidgets('bottom navigation switches sections on a phone-sized surface', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);

    expect(find.byType(AppBottomNavBar), findsOneWidget);
    expect(find.text('Weather'), findsWidgets);

    await tester.tap(find.text('Locations'));
    await tester.pumpAndSettle();

    expect(find.text('Where should we get your weather?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Use My Location'), findsOneWidget);
  });

  testWidgets('uses a navigation rail on wide surfaces instead of a bottom bar', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);

    expect(find.byType(AppNavRail), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsNothing);
  });

  testWidgets('adding a location switches the Weather tab out of its empty state', (tester) async {
    await pumpApp(tester);

    // The Weather tab's empty state only navigates to Locations; the actual
    // "add" action lives on that tab. Manual coordinate entry is now the
    // "Advanced" path off the onboarding view rather than the first thing
    // shown.
    await tester.tap(find.text('Go to Locations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter coordinates manually'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Home');
    await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '38.8894');
    await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '-77.0352');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Location'));
    await tester.tap(find.text('Add Location'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('No Locations Yet'), findsNothing);

    // Switching back to Weather now shows that location instead of the
    // empty state. The default test surface is tablet-width, where the
    // custom rail is compact (icon-only, no visible label text) -- the
    // destination's accessible name still exists as a Semantics label,
    // so tap through that rather than visible text.
    await tester.tap(find.bySemanticsLabel('Weather'));
    await tester.pumpAndSettle();
    expect(find.text('No Locations Yet'), findsNothing);
  });
}
