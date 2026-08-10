import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/empty_state.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/responsive_center.dart';
import '../../locations/application/locations_controller.dart';
import '../../weather/application/weather_controller.dart';
import 'alert_detail_screen.dart';
import 'widgets/alert_card.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(selectedLocationProvider);

    if (location == null) {
      return const EmptyState(
        icon: Icons.location_off_rounded,
        title: 'No Locations Yet',
        message:
            'Add a location from the Locations tab to see its weather alerts.',
      );
    }

    final weatherAsync = ref.watch(weatherControllerProvider(location));

    return Scaffold(
      appBar: AppBar(title: Text('Alerts · ${location.name}')),
      body: weatherAsync.when(
        data: (data) {
          if (data.alerts.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'No Active Alerts',
              message:
                  'There are no active National Weather Service alerts for this location.',
            );
          }
          return ResponsiveCenter(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: data.alerts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final alert = data.alerts[index];
                return AlertCard(
                  alert: alert,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AlertDetailScreen(alert: alert),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(weatherControllerProvider(location)),
        ),
      ),
    );
  }
}
