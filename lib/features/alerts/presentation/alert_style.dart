import 'package:flutter/material.dart';

import '../../../core/models/weather_alert.dart';
import '../../../theme/app_theme.dart';

/// Maps NWS alert severity to the accent color used across the alert card,
/// the Alerts tab, and the detail view — kept in one place so severity
/// always reads the same way everywhere it appears.
Color severityColor(AlertSeverity severity) {
  switch (severity) {
    case AlertSeverity.extreme:
      return AlertColors.extreme;
    case AlertSeverity.severe:
      return AlertColors.severe;
    case AlertSeverity.moderate:
      return AlertColors.moderate;
    case AlertSeverity.minor:
      return AlertColors.minor;
    case AlertSeverity.unknown:
      return AlertColors.unknown;
  }
}

String severityLabel(AlertSeverity severity) {
  switch (severity) {
    case AlertSeverity.extreme:
      return 'Extreme';
    case AlertSeverity.severe:
      return 'Severe';
    case AlertSeverity.moderate:
      return 'Moderate';
    case AlertSeverity.minor:
      return 'Minor';
    case AlertSeverity.unknown:
      return 'Unknown';
  }
}
