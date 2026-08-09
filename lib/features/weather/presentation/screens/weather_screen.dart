import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_shell.dart';
import '../../../../core/models/location.dart';
import '../../../../core/models/weather_data.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/responsive.dart';
import '../../../../widgets/section_card.dart';
import '../../../locations/application/locations_controller.dart';
import '../../application/weather_controller.dart';
import '../widgets/alerts_section.dart';
import '../widgets/current_conditions_card.dart';
import '../widgets/daily_forecast_list.dart';
import '../widgets/hourly_forecast_list.dart';
import '../widgets/weather_details_grid.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(location.name),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _refresh(context, ref, location),
          ),
        ],
      ),
      body: weatherAsync.when(
        data: (data) => _WeatherBody(data: data, onRefresh: () => _refresh(context, ref, location)),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
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

class _WeatherBody extends StatelessWidget {
  const _WeatherBody({required this.data, required this.onRefresh});

  final WeatherData data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final screenSize = screenSizeOf(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: screenSize == ScreenSize.desktop
          ? _DesktopLayout(data: data)
          : _CompactLayout(data: data, constrainWidth: screenSize == ScreenSize.tablet),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.data, this.constrainWidth = false});

  final WeatherData data;
  final bool constrainWidth;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CurrentConditionsCard(data: data),
        const SizedBox(height: 16),
        SectionCard(title: 'Hourly Forecast', child: HourlyForecastList(entries: data.hourly)),
        const SizedBox(height: 16),
        SectionCard(title: 'Forecast', child: DailyForecastList(entries: data.daily)),
        const SizedBox(height: 16),
        SectionCard(title: 'Details', child: WeatherDetailsGrid(observation: data.observation)),
        const SizedBox(height: 16),
        AlertsSection(alerts: data.alerts),
      ],
    );

    if (!constrainWidth) return content;
    return Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: content),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.data});

  final WeatherData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Plain top-aligned rows rather than IntrinsicHeight: GridView
              // (used inside the Details card) doesn't report a usable
              // intrinsic height, which left the Details card clipped
              // instead of the row growing to fit it.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: CurrentConditionsCard(data: data)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SectionCard(
                      title: 'Hourly Forecast',
                      child: HourlyForecastList(entries: data.hourly),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SectionCard(title: 'Forecast', child: DailyForecastList(entries: data.daily)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SectionCard(
                      title: 'Details',
                      child: WeatherDetailsGrid(observation: data.observation),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AlertsSection(alerts: data.alerts),
            ],
          ),
        ),
      ),
    );
  }
}
