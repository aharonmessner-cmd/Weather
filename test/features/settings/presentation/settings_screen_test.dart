import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/app/theme_controller.dart';
import 'package:weather/app/weather_metric_preferences_controller.dart';
import 'package:weather/app/zmanim_settings_controller.dart';
import 'package:weather/core/models/weather_metric.dart';
import 'package:weather/features/settings/presentation/advanced_zmanim_screen.dart';
import 'package:weather/features/settings/presentation/settings_screen.dart';

Future<ProviderContainer> _containerWithPrefs() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) {
  // The Settings screen now has several stacked cards (Appearance, Weather
  // Details' 7 switches, Zmanim, About) that don't all fit in the default
  // test surface height -- ListView only mounts elements near the
  // viewport, so widen the surface rather than scrolling to each item.
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
}

void main() {
  testWidgets('renders Appearance and About sections with System selected by default', (tester) async {
    final container = await _containerWithPrefs();
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(container.read(themeModeProvider), ThemeMode.system);

    final segmented = tester.widget<SegmentedButton<ThemeMode>>(find.byType(SegmentedButton<ThemeMode>));
    expect(segmented.selected, {ThemeMode.system});
  });

  testWidgets('selecting Dark updates the theme mode provider and persists it', (tester) async {
    final container = await _containerWithPrefs();
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    final segmented = tester.widget<SegmentedButton<ThemeMode>>(find.byType(SegmentedButton<ThemeMode>));
    expect(segmented.selected, {ThemeMode.dark});
  });

  testWidgets('selecting Light then reloading the controller restores the persisted mode', (tester) async {
    final container = await _containerWithPrefs();
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.light);

    // A fresh controller (as if the app restarted) reading the same prefs
    // should come back up already in Light mode.
    container.invalidate(themeModeProvider);
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  testWidgets('Show Zmanim defaults to on', (tester) async {
    final container = await _containerWithPrefs();
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text('Show Zmanim'), findsOneWidget);
    final toggle = tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Show Zmanim'));
    expect(toggle.value, isTrue);
    expect(container.read(showZmanimProvider), isTrue);
  });

  testWidgets('turning Show Zmanim off persists and updates the provider', (tester) async {
    final container = await _containerWithPrefs();
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Show Zmanim'));
    await tester.pumpAndSettle();

    expect(container.read(showZmanimProvider), isFalse);
  });

  testWidgets('tapping Advanced Zmanim navigates to the Advanced Zmanim screen', (tester) async {
    final container = await _containerWithPrefs();
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.tap(find.text('Advanced Zmanim'));
    await tester.pumpAndSettle();

    expect(find.byType(AdvancedZmanimScreen), findsOneWidget);
  });

  testWidgets('Weather Details section lists every WeatherMetric, all on by default', (tester) async {
    final container = await _containerWithPrefs();
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text('Weather Details'), findsOneWidget);
    for (final metric in WeatherMetric.values) {
      final tile = tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, metric.settingsLabel));
      expect(tile.value, isTrue, reason: '${metric.settingsLabel} should default to on');
    }
    expect(container.read(weatherMetricPreferencesProvider), WeatherMetric.values.toSet());
  });

  testWidgets('turning off a Weather Details metric persists and updates the provider', (tester) async {
    final container = await _containerWithPrefs();
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.tap(find.widgetWithText(SwitchListTile, 'UV Index'));
    await tester.pumpAndSettle();

    expect(container.read(weatherMetricPreferencesProvider).contains(WeatherMetric.uvIndex), isFalse);
    final tile = tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'UV Index'));
    expect(tile.value, isFalse);
  });
}
