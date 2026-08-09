import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode_v1';

  @override
  ThemeMode build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.firstWhere((mode) => mode.name == raw, orElse: () => ThemeMode.system);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
