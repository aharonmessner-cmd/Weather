import 'package:flutter/material.dart';

import '../../../../core/models/weather_alert.dart';
import '../alert_style.dart';

/// A single active alert, shown on both the weather dashboard's Alerts
/// section and the dedicated Alerts tab. Color-codes by severity so the
/// most urgent alerts stand out at a glance.
class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, this.onTap, this.contentColor});

  final WeatherAlert alert;
  final VoidCallback? onTap;

  /// Overrides the card's text/icon color — used when this card sits on
  /// the Weather screen's glass-over-sky background, where the ambient
  /// [Theme]'s text color follows [ThemeMode] (independent of the sky) and
  /// can land close to the card's own background color depending on the
  /// sky's current brightness. Left null on the flat Alerts tab and detail
  /// screen, where the ambient theme color is already correct.
  final Color? contentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = severityColor(alert.severity);
    final textColor = contentColor ?? theme.colorScheme.onSurface;
    final secondaryTextColor = contentColor?.withValues(alpha: 0.66) ?? theme.colorScheme.onSurfaceVariant;

    return Material(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
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
                    Text(alert.event, style: theme.textTheme.titleMedium?.copyWith(color: textColor)),
                    if (alert.areaDesc != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        alert.areaDesc!,
                        style: theme.textTheme.bodyMedium?.copyWith(color: secondaryTextColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }
}
