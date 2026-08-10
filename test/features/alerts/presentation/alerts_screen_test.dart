import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/services/nws/nws_api_client.dart';
import 'package:weather/features/alerts/presentation/alert_detail_screen.dart';
import 'package:weather/features/alerts/presentation/alerts_screen.dart';
import 'package:weather/features/locations/application/locations_controller.dart';
import 'package:weather/widgets/empty_state.dart';

import '../../../support/fixture.dart';

Future<ProviderContainer> _containerWithFixtures({bool noAlerts = false}) async {
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
      if (path.startsWith('/alerts/active')) {
        return http.Response(
          noAlerts ? '{"type":"FeatureCollection","features":[]}' : loadFixtureRaw('alerts_active.json'),
          200,
        );
      }
      return http.Response('not found', 404);
    }),
  );

  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    nwsApiClientProvider.overrideWithValue(client),
  ]);
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: AlertsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no saved locations shows the empty state, not a loading spinner', (tester) async {
    final container = await _containerWithFixtures();
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No Locations Yet'), findsOneWidget);
  });

  testWidgets('an active alert renders as a card and opens detail on tap', (tester) async {
    final container = await _containerWithFixtures();
    addTearDown(container.dispose);
    await container.read(locationsControllerProvider.notifier).add(
          name: 'Washington, DC',
          latitude: 38.8894,
          longitude: -77.0352,
        );
    await _pump(tester, container);

    expect(find.text('Alerts · Washington, DC'), findsOneWidget);
    expect(find.text('Heat Advisory'), findsOneWidget);

    await tester.tap(find.text('Heat Advisory'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDetailScreen), findsOneWidget);
    expect(find.text('Drink plenty of fluids, stay in an air-conditioned room.'), findsOneWidget);
  });

  testWidgets('no active alerts shows the "No Active Alerts" empty state', (tester) async {
    final container = await _containerWithFixtures(noAlerts: true);
    addTearDown(container.dispose);
    await container.read(locationsControllerProvider.notifier).add(
          name: 'Washington, DC',
          latitude: 38.8894,
          longitude: -77.0352,
        );
    await _pump(tester, container);

    expect(find.text('No Active Alerts'), findsOneWidget);
  });
}
