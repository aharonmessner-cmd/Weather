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
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color contentColor;
  final GlassStyle style;

  /// An optional small classification shown under [value] (e.g. UV
  /// Index's "Moderate"/"High"). Omitted entirely by every card that
  /// doesn't pass one, so this never affects the existing cards' layout.
  final String? caption;

  /// This card sits in a fixed-aspect-ratio grid cell (see
  /// [WeatherDetailsGrid]) that can't grow taller to fit larger text, so
  /// the system text scale is capped rather than left unbounded — large
  /// scale factors still get bigger, clearer text here, just not enough to
  /// blow out the cell height.
  static const _maxTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = contentColor.withValues(alpha: 0.62);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: _maxTextScale),
      ),
      child: GlassCard(
        style: style,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: secondaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    // Explicit tight line-height: the default font metrics'
                    // leading was enough to overflow the details grid's
                    // narrow-phone cell height by a couple of pixels even
                    // though the two lines of text visually fit fine.
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 12,
                      height: 1.1,
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
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: contentColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (caption != null)
                    Text(
                      caption!,
                      style: TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 10,
                        height: 1.1,
                        fontWeight: FontWeight.w500,
                        color: secondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
