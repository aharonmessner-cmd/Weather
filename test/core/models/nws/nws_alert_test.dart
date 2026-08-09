import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/nws/nws_alert.dart';

import '../../../support/fixture.dart';

void main() {
  group('NwsAlertsResponse.tryParse', () {
    test('parses active alert features', () {
      final json = loadFixture('alerts_active.json');
      final response = NwsAlertsResponse.tryParse(json);

      expect(response.alerts, hasLength(1));
      final alert = response.alerts.first;
      expect(alert.event, 'Heat Advisory');
      expect(alert.severity, 'Moderate');
      expect(alert.areaDesc, 'District of Columbia; Arlington, VA');
      expect(alert.senderName, 'NWS Baltimore MD/Washington DC');
      expect(alert.expires, DateTime.parse('2026-08-09T20:00:00-04:00'));
    });

    test('returns an empty list (not a crash) with no active alerts', () {
      final response = NwsAlertsResponse.tryParse({'features': <dynamic>[]});
      expect(response.alerts, isEmpty);
    });

    test('returns an empty list when features is missing entirely', () {
      final response = NwsAlertsResponse.tryParse(<String, dynamic>{});
      expect(response.alerts, isEmpty);
    });

    test('skips a feature missing required fields', () {
      final response = NwsAlertsResponse.tryParse({
        'features': [
          {
            'properties': {'headline': 'no event or id field'}
          }
        ]
      });
      expect(response.alerts, isEmpty);
    });
  });
}
