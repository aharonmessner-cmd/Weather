import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme_controller.dart';
import '../../../app/weather_metric_preferences_controller.dart';
import '../../../app/zmanim_settings_controller.dart';
import '../../../core/app_contact.dart';
import '../../../core/models/weather_metric.dart';
import '../../../widgets/responsive_center.dart';
import 'advanced_zmanim_screen.dart';

/// Deliberately minimal for V1: appearance and app/data attribution. Units,
/// notifications, and per-location preferences are natural additions here
/// once the core app is solid.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final showZmanim = ref.watch(showZmanimProvider);
    final enabledMetrics = ref.watch(weatherMetricPreferencesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearance', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_rounded),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_rounded),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_rounded),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (selection) => ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(selection.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weather Details', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    for (final metric in WeatherMetric.values)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(metric.settingsLabel),
                        value: enabledMetrics.contains(metric),
                        onChanged: (value) =>
                            ref.read(weatherMetricPreferencesProvider.notifier).setEnabled(metric, value),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Zmanim', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show Zmanim'),
                      subtitle: const Text("Today's remaining halachic times, at the bottom of Weather"),
                      value: showZmanim,
                      onChanged: (value) => ref.read(showZmanimProvider.notifier).setShowZmanim(value),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Advanced Zmanim'),
                      subtitle: const Text('Customize which Zmanim show, their names, calculations, and order'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdvancedZmanimScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text(
                      'Weather data is provided by the National Weather Service '
                      '(api.weather.gov), a public API of NOAA. Forecasts and alerts '
                      'are provided as-is and may not always be current — always '
                      'follow official guidance during severe weather.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Minute-by-minute precipitation timing is provided by Pirate Weather.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zmanim (halachic times) are provided by Hebcal.com, '
                      'licensed under CC BY 4.0.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${AppContact.appName} · a private weather app for personal use.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
