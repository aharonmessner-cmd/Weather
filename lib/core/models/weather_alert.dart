import 'package:equatable/equatable.dart';

import 'nws/nws_alert.dart';

/// Severity levels an alert can carry, ordered from least to most severe.
/// The ordering is meaningful: [compareTo]-style sorting on `index` puts the
/// most urgent alerts last/first depending on direction, and the UI uses it
/// to pick a color treatment.
enum AlertSeverity {
  unknown,
  minor,
  moderate,
  severe,
  extreme;

  static AlertSeverity fromNws(String? value) {
    switch (value) {
      case 'Minor':
        return AlertSeverity.minor;
      case 'Moderate':
        return AlertSeverity.moderate;
      case 'Severe':
        return AlertSeverity.severe;
      case 'Extreme':
        return AlertSeverity.extreme;
      default:
        return AlertSeverity.unknown;
    }
  }
}

/// An active NWS alert for a location, e.g. a Winter Storm Warning or Heat
/// Advisory.
class WeatherAlert extends Equatable {
  const WeatherAlert({
    required this.id,
    required this.event,
    required this.severity,
    this.headline,
    this.description,
    this.instruction,
    this.areaDesc,
    this.senderName,
    this.effective,
    this.expires,
  });

  final String id;
  final String event;
  final AlertSeverity severity;
  final String? headline;
  final String? description;
  final String? instruction;
  final String? areaDesc;
  final String? senderName;
  final DateTime? effective;
  final DateTime? expires;

  factory WeatherAlert.fromNws(NwsAlert alert) {
    return WeatherAlert(
      id: alert.id,
      event: alert.event,
      severity: AlertSeverity.fromNws(alert.severity),
      headline: alert.headline,
      description: alert.description,
      instruction: alert.instruction,
      areaDesc: alert.areaDesc,
      senderName: alert.senderName,
      effective: alert.effective,
      expires: alert.expires ?? alert.ends,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'event': event,
        'severity': severity.name,
        'headline': headline,
        'description': description,
        'instruction': instruction,
        'areaDesc': areaDesc,
        'senderName': senderName,
        'effective': effective?.toIso8601String(),
        'expires': expires?.toIso8601String(),
      };

  static WeatherAlert? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final event = json['event'];
    if (id is! String || event is! String) return null;
    return WeatherAlert(
      id: id,
      event: event,
      severity: AlertSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => AlertSeverity.unknown,
      ),
      headline: json['headline'] as String?,
      description: json['description'] as String?,
      instruction: json['instruction'] as String?,
      areaDesc: json['areaDesc'] as String?,
      senderName: json['senderName'] as String?,
      effective: DateTime.tryParse(json['effective'] as String? ?? ''),
      expires: DateTime.tryParse(json['expires'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => [id, event, severity, headline, effective, expires];
}
