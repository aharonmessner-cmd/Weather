import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/nws/nws_point.dart';

import '../../../support/fixture.dart';

void main() {
  group('NwsPoint.tryParse', () {
    test('parses a valid points response', () {
      final json = loadFixture('points.json');
      final point = NwsPoint.tryParse(json);

      expect(point, isNotNull);
      expect(point!.gridId, 'LWX');
      expect(point.gridX, 97);
      expect(point.gridY, 71);
      expect(point.forecastUrl, 'https://api.weather.gov/gridpoints/LWX/97,71/forecast');
      expect(point.forecastHourlyUrl, 'https://api.weather.gov/gridpoints/LWX/97,71/forecast/hourly');
      expect(point.observationStationsUrl, 'https://api.weather.gov/gridpoints/LWX/97,71/stations');
      expect(point.timeZone, 'America/New_York');
      expect(point.relativeCityName, 'Arlington');
      expect(point.relativeCityState, 'VA');
    });

    test('returns null when properties is missing', () {
      expect(NwsPoint.tryParse(<String, dynamic>{}), isNull);
    });

    test('returns null when a required field is missing', () {
      final json = loadFixture('points.json');
      (json['properties'] as Map<String, dynamic>).remove('forecast');
      expect(NwsPoint.tryParse(json), isNull);
    });

    test('returns null when gridX is not numeric', () {
      final json = loadFixture('points.json');
      (json['properties'] as Map<String, dynamic>)['gridX'] = 'not-a-number';
      expect(NwsPoint.tryParse(json), isNull);
    });

    test('tolerates a missing relativeLocation', () {
      final json = loadFixture('points.json');
      (json['properties'] as Map<String, dynamic>).remove('relativeLocation');
      final point = NwsPoint.tryParse(json);
      expect(point, isNotNull);
      expect(point!.relativeCityName, isNull);
    });
  });
}
