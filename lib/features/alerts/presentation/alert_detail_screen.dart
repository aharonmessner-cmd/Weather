import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/weather_alert.dart';
import '../../../widgets/responsive_center.dart';
import 'alert_style.dart';

/// Full text of a single alert: headline, description, instructions, area,
/// and timing — everything NWS provides beyond the compact card.
class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alert});

  final WeatherAlert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = severityColor(alert.severity);
    final timeFormat = DateFormat('EEE, MMM d · h:mm a');

    return Scaffold(
      appBar: AppBar(title: Text(alert.event)),
      body: ResponsiveCenter(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    severityLabel(alert.severity).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.event,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                    ),
                  ),
                  if (alert.headline != null) ...[
                    const SizedBox(height: 8),
                    Text(alert.headline!, style: theme.textTheme.bodyLarge),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                if (alert.effective != null)
                  _TimingLabel(
                    label: 'Effective',
                    value: timeFormat.format(alert.effective!.toLocal()),
                  ),
                if (alert.expires != null)
                  _TimingLabel(
                    label: 'Expires',
                    value: timeFormat.format(alert.expires!.toLocal()),
                  ),
              ],
            ),
            if (alert.areaDesc != null) ...[
              const SizedBox(height: 20),
              Text('Area', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(alert.areaDesc!, style: theme.textTheme.bodyLarge),
            ],
            if (alert.description != null) ...[
              const SizedBox(height: 20),
              Text('Details', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(alert.description!, style: theme.textTheme.bodyLarge),
            ],
            if (alert.instruction != null) ...[
              const SizedBox(height: 20),
              Text('Instructions', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(alert.instruction!, style: theme.textTheme.bodyLarge),
            ],
            if (alert.senderName != null) ...[
              const SizedBox(height: 24),
              Text(
                alert.senderName!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimingLabel extends StatelessWidget {
  const _TimingLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
