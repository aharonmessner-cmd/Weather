import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/zmanim/hebcal_zman_field.dart';
import '../core/models/zmanim/zman_definition.dart';
import '../core/models/zmanim/zmanim_configuration.dart';
import 'providers.dart';

/// "Show Zmanim" — the Settings toggle. Mirrors [ThemeModeController]'s
/// shape exactly. Default ON.
class ShowZmanimController extends Notifier<bool> {
  static const _key = 'show_zmanim_v1';

  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;
  }

  Future<void> setShowZmanim(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final showZmanimProvider = NotifierProvider<ShowZmanimController, bool>(ShowZmanimController.new);

/// The user's Zmanim display configuration (which rows, their display
/// names, which Hebcal calculation backs each, enabled state, and order)
/// -- see `Advanced Zmanim` in Settings. Entirely separate from
/// [showZmanimProvider]: that's a single on/off switch for the whole
/// section, this is what's *in* the section when it's on.
class ZmanimConfigurationController extends Notifier<ZmanimConfiguration> {
  static const _key = 'zmanim_configuration_v1';

  @override
  ZmanimConfiguration build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return ZmanimConfiguration.defaults();
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return ZmanimConfiguration.defaults();
      return ZmanimConfiguration.tryFromJson(json);
    } on FormatException {
      return ZmanimConfiguration.defaults();
    }
  }

  Future<void> _persist(ZmanimConfiguration config) async {
    state = config;
    await ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(config.toJson()));
  }

  Future<void> setEnabled(String id, bool enabled) {
    return _persist(_mapDefinitions((d) => d.id == id ? d.copyWith(enabled: enabled) : d));
  }

  /// The calculation/opinion currently powering [id]. The UI is
  /// responsible for only offering real alternatives (see
  /// `alternativesFor` in `zman_calculation_groups.dart`) so this never
  /// silently swaps in an unrelated zman.
  Future<void> setField(String id, HebcalZmanField field) {
    return _persist(_mapDefinitions((d) => d.id == id ? d.copyWith(field: field) : d));
  }

  Future<void> setDisplayName(String id, String displayName) {
    if (displayName.trim().isEmpty) return Future.value();
    return _persist(_mapDefinitions((d) => d.id == id ? d.copyWith(displayName: displayName.trim()) : d));
  }

  /// Moves the definition at [oldIndex] to [newIndex] -- order is purely
  /// list position (see `ZmanDefinition`'s doc comment), so reordering is
  /// just a list splice.
  Future<void> reorder(int oldIndex, int newIndex) {
    final defs = List<ZmanDefinition>.of(state.definitions);
    if (oldIndex < 0 || oldIndex >= defs.length) return Future.value();
    final moving = defs.removeAt(oldIndex);
    final clampedNewIndex = newIndex.clamp(0, defs.length);
    defs.insert(clampedNewIndex, moving);
    return _persist(ZmanimConfiguration(definitions: defs));
  }

  /// Adds a new row (typically one of `additionalZmanTemplates`) at the
  /// end of the list. A duplicate `id` is ignored rather than creating an
  /// ambiguous second row with the same identity.
  Future<void> addDefinition(ZmanDefinition definition) {
    if (state.definitions.any((d) => d.id == definition.id)) return Future.value();
    return _persist(ZmanimConfiguration(definitions: [...state.definitions, definition]));
  }

  Future<void> removeDefinition(String id) {
    return _persist(ZmanimConfiguration(definitions: state.definitions.where((d) => d.id != id).toList()));
  }

  Future<void> resetToDefaults() => _persist(ZmanimConfiguration.defaults());

  ZmanimConfiguration _mapDefinitions(ZmanDefinition Function(ZmanDefinition) transform) {
    return ZmanimConfiguration(definitions: state.definitions.map(transform).toList());
  }
}

final zmanimConfigurationProvider =
    NotifierProvider<ZmanimConfigurationController, ZmanimConfiguration>(ZmanimConfigurationController.new);
