import 'package:flutter/material.dart';

import '../../../../core/models/weather_data.dart';
import '../../../../widgets/last_updated_label.dart';
import '../../../../widgets/section_card.dart';
import '../../../../widgets/weather_icon.dart';

/// The hero card at the top of the dashboard: temperature, condition,
/// feels-like, today's high/low, and the location name.
class CurrentConditionsCard extends StatelessWidget {
  const CurrentConditionsCard({super.key, required this.data});

  final WeatherData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = data.current;
    final isStale = data.isStaleAsOf(DateTime.now());

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.location.name,
                      style: theme.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    LastUpdatedLabel(fetchedAt: data.fetchedAt, isStale: isStale),
                  ],
                ),
              ),
              WeatherIcon(
                condition: current.condition,
                isDaytime: current.isDaytime ?? true,
                size: 52,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            current.temperatureFahrenheit != null ? '${current.temperatureFahrenheit!.round()}°' : '--°',
            style: theme.textTheme.displayLarge,
          ),
          if (current.conditionText != null)
            Text(current.conditionText!, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 4,
            children: [
              if (current.feelsLikeFahrenheit != null)
                Text(
                  'Feels like ${current.feelsLikeFahrenheit!.round()}°',
                  style: theme.textTheme.bodyMedium,
                ),
              if (current.todayHighFahrenheit != null || current.todayLowFahrenheit != null)
                Text(
                  'H:${current.todayHighFahrenheit?.toString() ?? '--'}°  '
                  'L:${current.todayLowFahrenheit?.toString() ?? '--'}°',
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
