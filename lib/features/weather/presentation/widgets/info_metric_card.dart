import 'package:flutter/material.dart';

import '../../../../theme/app_typography.dart';
import '../../../../theme/glass_style.dart';
import '../../../../widgets/glass_card.dart';

/// A single small metric — icon, label, value — on a [GlassCard]. The
/// generalized building block for the weather-details grid (humidity, dew
/// point, visibility, pressure, gusts, last-hour precipitation, ...):
/// same shape for all of them, one place to keep the glass/typography
/// consistent.
class InfoMetricCard extends StatelessWidget {
  const InfoMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.contentColor,
    required this.style,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color contentColor;
  final GlassStyle style;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = contentColor.withValues(alpha: 0.62);
    return GlassCard(
      style: style,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: secondaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTypography.fontBody,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: secondaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTypography.fontDisplay,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: contentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
