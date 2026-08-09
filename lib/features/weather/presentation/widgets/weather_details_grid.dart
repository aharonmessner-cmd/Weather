import 'package:flutter/material.dart';

import '../../../../core/models/observation.dart';

/// The wind/humidity/dew point/visibility/pressure/precipitation grid,
/// sourced from the latest station [Observation]. Hidden entries (e.g. no
/// gust data) are simply omitted rather than shown as "--", since NWS
/// stations frequently don't report every field.
class WeatherDetailsGrid extends StatelessWidget {
  const WeatherDetailsGrid({super.key, required this.observation});

  final Observation? observation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final obs = observation;
    if (obs == null) {
      return Text('No current observation available.', style: theme.textTheme.bodyMedium);
    }

    final items = <_DetailItem>[
      _DetailItem(icon: Icons.air_rounded, label: 'Wind', value: _windText(obs)),
      if (obs.windGustMph != null)
        _DetailItem(icon: Icons.storm_rounded, label: 'Gusts', value: '${obs.windGustMph!.round()} mph'),
      _DetailItem(
        icon: Icons.water_drop_outlined,
        label: 'Humidity',
        value: obs.humidityPercent != null ? '${obs.humidityPercent!.round()}%' : '--',
      ),
      _DetailItem(
        icon: Icons.thermostat_outlined,
        label: 'Dew Point',
        value: obs.dewPointFahrenheit != null ? '${obs.dewPointFahrenheit!.round()}°' : '--',
      ),
      _DetailItem(
        icon: Icons.visibility_outlined,
        label: 'Visibility',
        value: obs.visibilityMiles != null ? '${obs.visibilityMiles!.toStringAsFixed(1)} mi' : '--',
      ),
      _DetailItem(
        icon: Icons.speed_outlined,
        label: 'Pressure',
        value: obs.pressureInHg != null ? '${obs.pressureInHg!.toStringAsFixed(2)} in' : '--',
      ),
      if (obs.precipitationLastHourInches != null)
        _DetailItem(
          icon: Icons.umbrella_outlined,
          label: 'Last Hour',
          value: '${obs.precipitationLastHourInches!.toStringAsFixed(2)} in',
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 420 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 18,
            crossAxisSpacing: 12,
            childAspectRatio: 2.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }

  static String _windText(Observation obs) {
    if (obs.windSpeedMph == null) return '--';
    final direction = obs.windDirectionCompass != null ? '${obs.windDirectionCompass} ' : '';
    return '$direction${obs.windSpeedMph!.round()} mph';
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text(value, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
