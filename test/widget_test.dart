import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/app.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/services/nws/nws_api_client.dart';

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

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Weather'), findsWidgets);

    await tester.tap(find.text('Locations'));
    await tester.pumpAndSettle();

    expect(find.text('No Locations Yet'), findsOneWidget);
    expect(find.text('Add a place — like Home, School, or Camp — to start seeing its weather.'), findsOneWidget);
  });

  testWidgets('uses a navigation rail on wide surfaces instead of a bottom bar', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('adding a location switches the Weather tab out of its empty state', (tester) async {
    await pumpApp(tester);

    // The Weather tab's empty state only navigates to Locations; the actual
    // "add" action lives on that tab.
    await tester.tap(find.text('Go to Locations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a Location'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Home');
    await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '38.8894');
    await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '-77.0352');
    await tester.tap(find.text('Add Location'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('No Locations Yet'), findsNothing);

    // Switching back to Weather now shows that location instead of the
    // empty state.
    await tester.tap(find.text('Weather'));
    await tester.pumpAndSettle();
    expect(find.text('No Locations Yet'), findsNothing);
  });
}
