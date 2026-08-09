import 'package:flutter/material.dart';

import '../../../../core/models/weather_alert.dart';
import '../../../../widgets/section_card.dart';
import '../../../alerts/presentation/alert_detail_screen.dart';
import '../../../alerts/presentation/widgets/alert_card.dart';

/// The dashboard's inline alerts section. Renders nothing at all when
/// there are no active alerts, rather than an empty "Alerts" card — the
/// dedicated Alerts tab is where "no active alerts" gets its own message.
class AlertsSection extends StatelessWidget {
  const AlertsSection({super.key, required this.alerts});

  final List<WeatherAlert> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: alerts.length == 1 ? 'Alert' : 'Alerts (${alerts.length})',
      child: Column(
        children: [
          for (var i = 0; i < alerts.length; i++) ...[
            AlertCard(
              alert: alerts[i],
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
