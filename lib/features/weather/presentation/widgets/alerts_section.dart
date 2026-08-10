import 'package:flutter/material.dart';

import '../../../../core/models/weather_alert.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/glass_style.dart';
import '../../../../widgets/glass_card.dart';
import '../../../alerts/presentation/alert_detail_screen.dart';
import '../../../alerts/presentation/widgets/alert_card.dart';

/// The dashboard's inline alerts section. Renders nothing at all when
/// there are no active alerts, rather than an empty "Alerts" card — the
/// dedicated Alerts tab is where "no active alerts" gets its own message.
class AlertsSection extends StatelessWidget {
  const AlertsSection({
    super.key,
    required this.alerts,
    required this.contentColor,
    required this.style,
  });

  final List<WeatherAlert> alerts;
  final Color contentColor;
  final GlassStyle style;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      style: style,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            alerts.length == 1 ? 'Alert' : 'Alerts (${alerts.length})',
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: contentColor.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < alerts.length; i++) ...[
            AlertCard(
              alert: alerts[i],
              contentColor: contentColor,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: alerts[i])),
              ),
            ),
            if (i != alerts.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
