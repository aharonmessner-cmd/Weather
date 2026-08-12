import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../features/alerts/presentation/alerts_screen.dart';
import '../features/locations/application/locations_controller.dart';
import '../features/locations/presentation/locations_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/weather/application/weather_controller.dart';
import '../features/weather/presentation/screens/weather_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_platform.dart';
import '../widgets/responsive.dart';
import 'navigation/app_bottom_nav_bar.dart';
import 'navigation/app_nav_rail.dart';
import 'navigation/nav_glyphs.dart';
import 'navigation/nav_item.dart';
import 'navigation/nav_style.dart';

enum AppSection { weather, locations, alerts, settings }

/// Which top-level section is showing. A plain [StateProvider] (rather than
/// a `Navigator`/routes) is enough for four flat, always-available tabs —
/// nothing here needs deep-linking or a back stack.
final appShellSectionProvider = StateProvider<AppSection>((ref) => AppSection.weather);

final _activeAlertCountProvider = Provider<int>((ref) {
  final location = ref.watch(selectedLocationProvider);
  if (location == null) return 0;
  return ref.watch(weatherControllerProvider(location)).value?.alerts.length ?? 0;
});

class _Destination {
  const _Destination({
    required this.section,
    required this.glyph,
    required this.label,
  });

  final AppSection section;
  final NavGlyphKind glyph;
  final String label;
}

const _destinations = [
  _Destination(section: AppSection.weather, glyph: NavGlyphKind.weather, label: 'Weather'),
  _Destination(section: AppSection.locations, glyph: NavGlyphKind.locations, label: 'Locations'),
  _Destination(section: AppSection.alerts, glyph: NavGlyphKind.alerts, label: 'Alerts'),
  _Destination(section: AppSection.settings, glyph: NavGlyphKind.settings, label: 'Settings'),
];

const _screens = <AppSection, Widget>{
  AppSection.weather: WeatherScreen(),
  AppSection.locations: LocationsScreen(),
  AppSection.alerts: AlertsScreen(),
  AppSection.settings: SettingsScreen(),
};

/// The app's top-level navigation shell: a bottom nav bar on phones, a side
/// rail on tablets and desktop web, per the platform-appropriate navigation
/// requirement.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(appShellSectionProvider);
    final screenSize = screenSizeOf(context);
    final selectedIndex = _destinations.indexWhere((d) => d.section == section);
    final alertCount = ref.watch(_activeAlertCountProvider);
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light;
    final platform = currentAppPlatform;
    final navStyle = NavPlatformStyle.of(platform, palette, theme.brightness);
    final accentColor = theme.colorScheme.primary;

    void onSelect(int index) => ref.read(appShellSectionProvider.notifier).state = _destinations[index].section;

    final items = [
      for (final d in _destinations)
        NavItemData(
          glyph: d.glyph,
          label: d.label,
          badgeCount: d.section == AppSection.alerts ? alertCount : 0,
        ),
    ];

    // A plain widget swap rather than an IndexedStack: with only four
    // lightweight tabs, rebuilding on switch is cheap, and it avoids every
    // unvisited tab's empty/loading state being simultaneously present in
    // the tree (which, among other things, made "no locations yet" appear
    // more than once at once).
    final body = _screens[section]!;

    if (screenSize == ScreenSize.mobile) {
      return Scaffold(
        body: body,
        bottomNavigationBar: AppBottomNavBar(
          items: items,
          selectedIndex: selectedIndex,
          onSelected: onSelect,
          style: navStyle,
          palette: palette,
          accentColor: accentColor,
        ),
      );
    }

    final extended = screenSize == ScreenSize.desktop;
    return Scaffold(
      body: Row(
        children: [
          AppNavRail(
            items: items,
            selectedIndex: selectedIndex,
            onSelected: onSelect,
            style: navStyle,
            palette: palette,
            accentColor: accentColor,
            extended: extended,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
