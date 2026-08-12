import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_shell.dart';
import '../../../../core/models/location.dart';
import '../../../../core/models/weather_data.dart';
import '../../../../core/utils/sun_times.dart';
import '../../../../environment/weather_environment.dart';
import '../../../../theme/glass_style.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/last_updated_label.dart';
import '../../../../widgets/responsive.dart';
import '../../../../widgets/responsive_center.dart';
import '../../../locations/application/locations_controller.dart';
import '../../application/weather_controller.dart';
import '../widgets/alerts_section.dart';
import '../widgets/city_pager.dart';
import '../widgets/daily_forecast_list.dart';
import '../widgets/hourly_forecast_list.dart';
import '../widgets/minutecast_section.dart';
import '../widgets/weather_details_grid.dart';
import '../widgets/weather_hero_section.dart';
import '../widgets/zmanim_section.dart';

/// The Weather tab: a real-time [WeatherEnvironment] sky filling the
/// screen, with the hero temperature and every forecast card sitting
/// directly on it. "You're looking through a window at the current sky" —
/// see the module doc on [WeatherEnvironment] for the full design
/// rationale. The loading/error/no-location states stay plain (no sky):
/// there's no resolved condition to render a sky from yet.
class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(selectedLocationProvider);

    if (location == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weather')),
        body: EmptyState(
          icon: Icons.add_location_alt_outlined,
          title: 'No Locations Yet',
          message: 'Add a location to see its current conditions, forecast, and alerts.',
          action: FilledButton.icon(
            onPressed: () => ref.read(appShellSectionProvider.notifier).state = AppSection.locations,
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Go to Locations'),
          ),
        ),
      );
    }

    final weatherAsync = ref.watch(weatherControllerProvider(location));

    return weatherAsync.when(
      data: (data) => _WeatherBody(location: location, data: data, onRefresh: () => _refresh(context, ref, location)),
      loading: () => Scaffold(
        appBar: AppBar(title: Text(location.name)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(location.name)),
        body: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(weatherControllerProvider(location)),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref, Location location) async {
    try {
      await ref.read(weatherControllerProvider(location).notifier).refresh();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't refresh — showing the last saved weather.")),
        );
      }
    }
  }
}

class _WeatherBody extends ConsumerWidget {
  const _WeatherBody({required this.location, required this.data, required this.onRefresh});

  final Location location;
  final WeatherData data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final locations = ref.watch(locationsControllerProvider);

    return Scaffold(
      body: WeatherEnvironment(
        condition: data.current.condition,
        now: now,
        latitude: location.latitude,
        longitude: location.longitude,
        temperatureFahrenheit: data.current.temperatureFahrenheit,
        child: Builder(
          builder: (context) {
            final palette = WeatherEnvironment.paletteOf(context);
            final isDarkSky = palette.heroContentBrightness == Brightness.dark;
            final contentColor = isDarkSky ? Colors.white : const Color(0xFF12141C);
            final style = GlassStyle.onSky(palette.heroContentBrightness);
            final sunTimes = computeSunTimes(latitude: location.latitude, longitude: location.longitude, date: now);
            final isStale = data.isStaleAsOf(now);

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: screenSizeOf(context) == ScreenSize.desktop
                    ? _DesktopLayout(
                        data: data,
                        locations: locations,
                        contentColor: contentColor,
                        style: style,
                        sunTimes: sunTimes,
                        now: now,
                        isStale: isStale,
                        onSelectLocation: (id) => ref.read(selectedLocationIdProvider.notifier).state = id,
                        onRefresh: onRefresh,
                      )
                    : _CompactLayout(
                        data: data,
                        locations: locations,
                        contentColor: contentColor,
                        style: style,
                        sunTimes: sunTimes,
                        now: now,
                        isStale: isStale,
                        constrainWidth: screenSizeOf(context) == ScreenSize.tablet,
                        onSelectLocation: (id) => ref.read(selectedLocationIdProvider.notifier).state = id,
                        onRefresh: onRefresh,
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.contentColor,
    required this.fetchedAt,
    required this.isStale,
    required this.onRefresh,
  });

  final Color contentColor;
  final DateTime fetchedAt;
  final bool isStale;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Row(
        children: [
          Expanded(child: LastUpdatedLabel(fetchedAt: fetchedAt, isStale: isStale, color: contentColor.withValues(alpha: 0.6))),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, color: contentColor.withValues(alpha: 0.85)),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.data,
    required this.locations,
    required this.contentColor,
    required this.style,
    required this.sunTimes,
    required this.now,
    required this.isStale,
    required this.onSelectLocation,
    required this.onRefresh,
    this.constrainWidth = false,
  });

  final WeatherData data;
  final List<Location> locations;
  final Color contentColor;
  final GlassStyle style;
  final SunTimes sunTimes;
  final DateTime now;
  final bool isStale;
  final ValueChanged<String> onSelectLocation;
  final Future<void> Function() onRefresh;
  final bool constrainWidth;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _TopBar(contentColor: contentColor, fetchedAt: data.fetchedAt, isStale: isStale, onRefresh: onRefresh),
        WeatherHeroSection(
          locationName: data.location.name,
          current: data.current,
          locationSwitcher: CityPager(
            locations: locations,
            selectedId: data.location.id,
            onSelect: onSelectLocation,
            contentColor: contentColor,
          ),
        ),
        const SizedBox(height: 24),
        MinuteCastSection(location: data.location, contentColor: contentColor, style: style, timeZone: data.timeZone),
        const SizedBox(height: 16),
        HourlyForecastList(
          entries: data.hourly,
          contentColor: contentColor,
          style: style,
          isDaytime: data.current.isDaytime ?? true,
          timeZone: data.timeZone,
        ),
        const SizedBox(height: 16),
        DailyForecastList(entries: data.daily, contentColor: contentColor, style: style),
        const SizedBox(height: 16),
        WeatherDetailsGrid(
          observation: data.observation,
          location: data.location,
          hourlyEntries: data.hourly,
          sunTimes: sunTimes,
          now: now,
          contentColor: contentColor,
          style: style,
          timeZone: data.timeZone,
          feelsLikeFahrenheit: data.current.feelsLikeFahrenheit,
        ),
        const SizedBox(height: 16),
        AlertsSection(alerts: data.alerts, contentColor: contentColor, style: style),
        const SizedBox(height: 16),
        ZmanimSection(location: data.location, contentColor: contentColor, style: style, timeZone: data.timeZone),
      ],
    );

    if (!constrainWidth) return content;
    return ResponsiveCenter(child: content);
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.data,
    required this.locations,
    required this.contentColor,
    required this.style,
    required this.sunTimes,
    required this.now,
    required this.isStale,
    required this.onSelectLocation,
    required this.onRefresh,
  });

  final WeatherData data;
  final List<Location> locations;
  final Color contentColor;
  final GlassStyle style;
  final SunTimes sunTimes;
  final DateTime now;
  final bool isStale;
  final ValueChanged<String> onSelectLocation;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _TopBar(contentColor: contentColor, fetchedAt: data.fetchedAt, isStale: isStale, onRefresh: onRefresh),
              WeatherHeroSection(
                locationName: data.location.name,
                current: data.current,
                locationSwitcher: CityPager(
                  locations: locations,
                  selectedId: data.location.id,
                  onSelect: onSelectLocation,
                  contentColor: contentColor,
                ),
              ),
              const SizedBox(height: 24),
              MinuteCastSection(location: data.location, contentColor: contentColor, style: style, timeZone: data.timeZone),
              const SizedBox(height: 16),
              HourlyForecastList(
                entries: data.hourly,
                contentColor: contentColor,
                style: style,
                isDaytime: data.current.isDaytime ?? true,
                timeZone: data.timeZone,
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: DailyForecastList(entries: data.daily, contentColor: contentColor, style: style)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: WeatherDetailsGrid(
                      observation: data.observation,
                      location: data.location,
                      hourlyEntries: data.hourly,
                      sunTimes: sunTimes,
                      now: now,
                      contentColor: contentColor,
                      style: style,
                      timeZone: data.timeZone,
                      feelsLikeFahrenheit: data.current.feelsLikeFahrenheit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AlertsSection(alerts: data.alerts, contentColor: contentColor, style: style),
              const SizedBox(height: 20),
              ZmanimSection(location: data.location, contentColor: contentColor, style: style, timeZone: data.timeZone),
            ],
          ),
        ),
      ),
    );
  }
}
