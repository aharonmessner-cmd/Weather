import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../features/alerts/presentation/alerts_screen.dart';
import '../features/locations/application/locations_controller.dart';
import '../features/locations/presentation/locations_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/weather/application/weather_controller.dart';
import '../features/weather/presentation/screens/weather_screen.dart';
import '../widgets/responsive.dart';

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
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final AppSection section;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _destinations = [
  _Destination(
    section: AppSection.weather,
    icon: Icons.wb_sunny_outlined,
    selectedIcon: Icons.wb_sunny_rounded,
    label: 'Weather',
  ),
  _Destination(
    section: AppSection.locations,
    icon: Icons.location_on_outlined,
    selectedIcon: Icons.location_on_rounded,
    label: 'Locations',
  ),
  _Destination(
    section: AppSection.alerts,
    icon: Icons.warning_amber_outlined,
    selectedIcon: Icons.warning_rounded,
    label: 'Alerts',
  ),
  _Destination(
    section: AppSection.settings,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    label: 'Settings',
  ),
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

    void onSelect(int index) => ref.read(appShellSectionProvider.notifier).state = _destinations[index].section;

    // A plain widget swap rather than an IndexedStack: with only four
    // lightweight tabs, rebuilding on switch is cheap, and it avoids every
    // unvisited tab's empty/loading state being simultaneously present in
    // the tree (which, among other things, made "no locations yet" appear
    // more than once at once).
    final body = _screens[section]!;

    if (screenSize == ScreenSize.mobile) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelect,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: _destinationIcon(d, alertCount, selected: false),
                selectedIcon: _destinationIcon(d, alertCount, selected: true),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final extended = screenSize == ScreenSize.desktop;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 200,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelect,
            leading: extended
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Icon(Icons.cloud_rounded, size: 32),
                  )
                : const SizedBox(height: 16),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: _destinationIcon(d, alertCount, selected: false),
                  selectedIcon: _destinationIcon(d, alertCount, selected: true),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _destinationIcon(_Destination destination, int alertCount, {required bool selected}) {
    final icon = Icon(selected ? destination.selectedIcon : destination.icon);
    if (destination.section != AppSection.alerts || alertCount == 0) return icon;
    return Badge(label: Text('$alertCount'), child: icon);
  }
}
