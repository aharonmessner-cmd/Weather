import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/nws/nws_observation.dart';

import '../../../support/fixture.dart';

void main() {
  group('NwsObservation.tryParse', () {
    test('parses a fully-populated observation', () {
      final json = loadFixture('observation_latest.json');
      final obs = NwsObservation.tryParse(json);

      expect(obs, isNotNull);
      expect(obs!.timestamp, DateTime.parse('2026-08-09T17:52:00+00:00'));
      expect(obs.textDescription, 'Mostly Cloudy');
      expect(obs.temperatureCelsius, closeTo(32.8, 0.001));
      expect(obs.dewpointCelsius, closeTo(21.7, 0.001));
      expect(obs.windDirectionDegrees, closeTo(210, 0.001));
      expect(obs.windSpeedKmh, closeTo(14.8, 0.001));
      expect(obs.barometricPressurePa, closeTo(101830, 0.001));
      expect(obs.visibilityMeters, closeTo(16090, 0.001));
      expect(obs.relativeHumidityPercent, closeTo(54.7, 0.001));
      expect(obs.heatIndexCelsius, closeTo(34.9, 0.001));
    });

    test('missing/null quantitative values parse as null, not zero or a crash', () {
      final json = loadFixture('observation_latest.json');
      final obs = NwsObservation.tryParse(json)!;

      expect(obs.windGustKmh, isNull);
      expect(obs.windChillCelsius, isNull);
      expect(obs.precipitationLastHourMm, isNull);
    });

    test('returns null when properties is missing', () {
      expect(NwsObservation.tryParse(<String, dynamic>{}), isNull);
    });

    test('tolerates an observation station reporting almost nothing', () {
      final obs = NwsObservation.tryParse({
        'properties': {'timestamp': '2026-08-09T17:52:00+00:00'}
      });
      expect(obs, isNotNull);
      expect(obs!.temperatureCelsius, isNull);
      expect(obs.windSpeedKmh, isNull);
    });
  });
}
