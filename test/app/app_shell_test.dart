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
import 'package:weather/core/services/nws/nws_api_client.dart';
import 'package:weather/features/locations/application/locations_controller.dart';

import '../support/fixture.dart';

/// Seeds one saved location and lets its weather (including the fixture's
/// one active alert) load through the real provider stack, so the shell's
/// alert badge has something real to count instead of being tested in
/// isolation against a private provider this test file can't reach.
Future<WidgetTester> _pumpAppWithAlert(WidgetTester tester, {Size size = const Size(1280, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final client = NwsApiClient(
    httpClient: MockClient((request) async {
      final path = request.url.path;
      if (path.startsWith('/points/')) return http.Response(loadFixtureRaw('points.json'), 200);
      if (path.contains('/forecast/hourly')) return http.Response(loadFixtureRaw('forecast_hourly.json'), 200);
      if (path.contains('/forecast')) return http.Response(loadFixtureRaw('forecast.json'), 200);
      if (path.contains('/stations') && !path.contains('/observations')) {
        return http.Response(loadFixtureRaw('stations.json'), 200);
      }
      if (path.contains('/observations/latest')) return http.Response(loadFixtureRaw('observation_latest.json'), 200);
      if (path.startsWith('/alerts/active')) return http.Response(loadFixtureRaw('alerts_active.json'), 200);
      return http.Response('not found', 404);
    }),
  );

  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    nwsApiClientProvider.overrideWithValue(client),
  ]);
  addTearDown(container.dispose);

  await container.read(locationsControllerProvider.notifier).add(
        name: 'Washington, DC',
        latitude: 38.8894,
        longitude: -77.0352,
      );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WeatherApp()),
  );
  // Let the async weather fetch (and its one active alert) resolve.
  await tester.pumpAndSettle();
  return tester;
}

void main() {
  testWidgets('shows an alert-count badge on the Alerts destination once data loads', (tester) async {
    await _pumpAppWithAlert(tester);

    expect(find.text('1'), findsOneWidget); // the badge count
  });

  testWidgets('tapping each destination navigates to that section', (tester) async {
    await _pumpAppWithAlert(tester);

    await tester.tap(find.text('Alerts').first);
    await tester.pumpAndSettle();
    expect(find.text('Heat Advisory'), findsWidgets);

    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.text('Locations').first);
    await tester.pumpAndSettle();
    expect(find.text('Washington, DC'), findsWidgets);

    await tester.tap(find.text('Weather').first);
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsNothing);
  });

  testWidgets('tablet width uses a compact (non-extended) rail', (tester) async {
    await _pumpAppWithAlert(tester, size: const Size(700, 900));

    expect(find.byType(AppNavRail), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsNothing);
    expect(tester.widget<AppNavRail>(find.byType(AppNavRail)).extended, isFalse);
  });

  testWidgets('desktop width uses an extended rail', (tester) async {
    await _pumpAppWithAlert(tester, size: const Size(1280, 900));

    expect(find.byType(AppNavRail), findsOneWidget);
    expect(tester.widget<AppNavRail>(find.byType(AppNavRail)).extended, isTrue);
    // Extended rails always show their destination labels.
    expect(find.text('Locations'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('phone width uses a bottom NavigationBar instead of a rail', (tester) async {
    await _pumpAppWithAlert(tester, size: const Size(390, 844));

    expect(find.byType(AppBottomNavBar), findsOneWidget);
    expect(find.byType(AppNavRail), findsNothing);
  });

  group('responsive navigation sweep', () {
    // 320/390/430 = narrow/normal/large phone widths; 700 = tablet;
    // 1024 = the desktop breakpoint itself; 1600 = wide desktop.
    for (final width in [320.0, 390.0, 430.0, 700.0, 1024.0, 1600.0]) {
      testWidgets('renders without overflow or clipping at width $width', (tester) async {
        await _pumpAppWithAlert(tester, size: Size(width, 900));

        // Exactly one nav surface for a given breakpoint, never both.
        final hasBar = find.byType(AppBottomNavBar).evaluate().isNotEmpty;
        final hasRail = find.byType(AppNavRail).evaluate().isNotEmpty;
        expect(hasBar ^ hasRail, isTrue, reason: 'exactly one of bottom bar / rail at width $width');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
