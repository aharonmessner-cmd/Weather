import '../../utils/nws_json.dart';

/// Raw parse of a single feature from `GET /alerts/active`.
class NwsAlert {
  const NwsAlert({
    required this.id,
    required this.event,
    this.headline,
    this.description,
    this.instruction,
    this.severity,
    this.certainty,
    this.urgency,
    this.areaDesc,
    this.senderName,
    this.status,
    this.messageType,
    this.effective,
    this.onset,
    this.expires,
    this.ends,
  });

  final String id;
  final String event;
  final String? headline;
  final String? description;
  final String? instruction;

  /// One of `Extreme`, `Severe`, `Moderate`, `Minor`, `Unknown`.
  final String? severity;
  final String? certainty;
  final String? urgency;
  final String? areaDesc;
  final String? senderName;
  final String? status;
  final String? messageType;

  final DateTime? effective;
  final DateTime? onset;
  final DateTime? expires;
  final DateTime? ends;

  static NwsAlert? tryParse(Map<String, dynamic> json) {
    final properties = json['properties'];
    if (properties is! Map<String, dynamic>) return null;

    final id = nwsAsString(properties['id']) ?? nwsAsString(json['id']);
    final event = nwsAsString(properties['event']);
    if (id == null || event == null) return null;

    return NwsAlert(
      id: id,
      event: event,
      headline: nwsAsString(properties['headline']),
      description: nwsAsString(properties['description']),
      instruction: nwsAsString(properties['instruction']),
      severity: nwsAsString(properties['severity']),
      certainty: nwsAsString(properties['certainty']),
      urgency: nwsAsString(properties['urgency']),
      areaDesc: nwsAsString(properties['areaDesc']),
      senderName: nwsAsString(properties['senderName']),
      status: nwsAsString(properties['status']),
      messageType: nwsAsString(properties['messageType']),
      effective: nwsAsDateTime(properties['effective']),
      onset: nwsAsDateTime(properties['onset']),
      expires: nwsAsDateTime(properties['expires']),
      ends: nwsAsDateTime(properties['ends']),
    );
  }
}

/// Raw parse of `GET /alerts/active` (or `/alerts/active?point=...`).
class NwsAlertsResponse {
  const NwsAlertsResponse({required this.alerts});

  final List<NwsAlert> alerts;

  static NwsAlertsResponse tryParse(Map<String, dynamic> json) {
    final features = nwsAsMapList(json['features']);
    final alerts = features.map(NwsAlert.tryParse).whereType<NwsAlert>().toList();
    return NwsAlertsResponse(alerts: alerts);
  }
}
