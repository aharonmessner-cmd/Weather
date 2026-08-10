import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/app/theme_controller.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
}

void main() {
  test('defaults to ThemeMode.system when nothing has been persisted', () async {
    final container = await _container();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('setThemeMode updates state immediately', () async {
    final container = await _container();
    addTearDown(container.dispose);

    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('a persisted mode is restored by a fresh controller reading the same storage', () async {
    final container = await _container();
    addTearDown(container.dispose);
    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);

    container.invalidate(themeModeProvider);

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('an unrecognized persisted value falls back to system rather than throwing', () async {
    SharedPreferences.setMockInitialValues({'theme_mode_v1': 'not-a-real-mode'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
  });
}
