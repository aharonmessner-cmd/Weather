import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/nws/nws_alert.dart';
import 'package:weather/core/models/weather_alert.dart';

import '../../support/fixture.dart';

void main() {
  group('AlertSeverity.fromNws', () {
    test('maps known severity strings', () {
      expect(AlertSeverity.fromNws('Extreme'), AlertSeverity.extreme);
      expect(AlertSeverity.fromNws('Severe'), AlertSeverity.severe);
      expect(AlertSeverity.fromNws('Moderate'), AlertSeverity.moderate);
      expect(AlertSeverity.fromNws('Minor'), AlertSeverity.minor);
    });

    test('maps unknown or missing severity to unknown rather than throwing', () {
      expect(AlertSeverity.fromNws('Unknown'), AlertSeverity.unknown);
      expect(AlertSeverity.fromNws(null), AlertSeverity.unknown);
      expect(AlertSeverity.fromNws('SomethingNwsInventedLater'), AlertSeverity.unknown);
    });
  });

  group('WeatherAlert.fromNws / JSON round-trip', () {
    test('converts a raw alert and survives a JSON round-trip', () {
      final raw = NwsAlertsResponse.tryParse(loadFixture('alerts_active.json')).alerts.single;
      final alert = WeatherAlert.fromNws(raw);

      expect(alert.event, 'Heat Advisory');
      expect(alert.severity, AlertSeverity.moderate);

      final roundTripped = WeatherAlert.tryFromJson(alert.toJson());
      expect(roundTripped, alert);
    });
  });
}
