import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/nws/nws_observation.dart';
import 'package:weather/core/models/observation.dart';

import '../../support/fixture.dart';

void main() {
  group('Observation.fromNws', () {
    test('converts SI units from the raw observation to US customary units', () {
      final raw = NwsObservation.tryParse(loadFixture('observation_latest.json'))!;
      final obs = Observation.fromNws(raw, stationId: 'KDCA', stationName: 'Reagan National');

      expect(obs.temperatureFahrenheit, closeTo(91.04, 0.01));
      expect(obs.windSpeedMph, closeTo(9.2, 0.05));
      expect(obs.visibilityMiles, closeTo(10.0, 0.05));
      expect(obs.windDirectionCompass, 'SSW');
      expect(obs.stationId, 'KDCA');
    });

    test('feelsLikeFahrenheit prefers heat index when present', () {
      final raw = NwsObservation.tryParse(loadFixture('observation_latest.json'))!;
      final obs = Observation.fromNws(raw);
      // Fixture has a heat index of 34.9C ~= 94.8F, distinct from actual temp.
      expect(obs.feelsLikeFahrenheit, closeTo(94.82, 0.01));
    });

    test('feelsLikeFahrenheit falls back to wind chill, then actual temperature', () {
      final coldRaw = NwsObservation.tryParse({
        'properties': {
          'temperature': {'value': -5.0},
          'windChill': {'value': -12.0},
        }
      })!;
      expect(Observation.fromNws(coldRaw).feelsLikeFahrenheit, closeTo(celsiusToF(-12.0), 0.01));

      final plainRaw = NwsObservation.tryParse({
        'properties': {
          'temperature': {'value': 20.0},
        }
      })!;
      expect(Observation.fromNws(plainRaw).feelsLikeFahrenheit, closeTo(celsiusToF(20.0), 0.01));
    });

    test('handles a station reporting no data at all', () {
      final raw = NwsObservation.tryParse({'properties': <String, dynamic>{}})!;
      final obs = Observation.fromNws(raw);
      expect(obs.temperatureFahrenheit, isNull);
      expect(obs.feelsLikeFahrenheit, isNull);
      expect(obs.windDirectionCompass, isNull);
    });
  });

  group('Observation JSON round-trip', () {
    test('toJson/fromJson preserves values', () {
      final raw = NwsObservation.tryParse(loadFixture('observation_latest.json'))!;
      final obs = Observation.fromNws(raw, stationId: 'KDCA', stationName: 'Reagan National');

      final roundTripped = Observation.fromJson(obs.toJson());

      expect(roundTripped.temperatureFahrenheit, obs.temperatureFahrenheit);
      expect(roundTripped.stationId, obs.stationId);
      expect(roundTripped.condition, obs.condition);
      expect(roundTripped.observedAt, obs.observedAt);
    });
  });
}

double celsiusToF(double c) => c * 9 / 5 + 32;
