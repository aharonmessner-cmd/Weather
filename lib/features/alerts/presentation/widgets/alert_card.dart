import 'package:flutter/material.dart';

import '../../../../core/models/weather_alert.dart';
import '../alert_style.dart';

/// A single active alert, shown on both the weather dashboard's Alerts
/// section and the dedicated Alerts tab. Color-codes by severity so the
/// most urgent alerts stand out at a glance.
class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, this.onTap});

  final WeatherAlert alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = severityColor(alert.severity);

    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      severityLabel(alert.severity).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(alert.event, style: theme.textTheme.titleMedium),
                    if (alert.areaDesc != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        alert.areaDesc!,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
