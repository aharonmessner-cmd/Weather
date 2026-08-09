import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/nws/nws_forecast_period.dart';

import '../../../support/fixture.dart';

void main() {
  group('NwsForecast.tryParse', () {
    test('parses all periods from a forecast response', () {
      final json = loadFixture('forecast.json');
      final forecast = NwsForecast.tryParse(json);

      expect(forecast, isNotNull);
      expect(forecast!.periods, hasLength(4));
      expect(forecast.updated, DateTime.parse('2026-08-09T16:23:01+00:00'));
    });

    test('parses a fully-populated period', () {
      final json = loadFixture('forecast.json');
      final forecast = NwsForecast.tryParse(json)!;
      final first = forecast.periods.first;

      expect(first.name, 'This Afternoon');
      expect(first.isDaytime, isTrue);
      expect(first.temperature, 91);
      expect(first.temperatureUnit, 'F');
      expect(first.probabilityOfPrecipitationPercent, 40);
      expect(first.dewpointCelsius, closeTo(21.1, 0.001));
      expect(first.relativeHumidityPercent, closeTo(55, 0.001));
      expect(first.windSpeed, '10 mph');
      expect(first.windGust, '20 mph');
      expect(first.windDirection, 'SW');
      expect(first.shortForecast, 'Chance Showers And Thunderstorms');
    });

    test('treats a null quantitative value as missing rather than crashing', () {
      final json = loadFixture('forecast.json');
      final forecast = NwsForecast.tryParse(json)!;
      final thirdPeriod = forecast.periods[2];

      expect(thirdPeriod.probabilityOfPrecipitationPercent, isNull);
      expect(thirdPeriod.windGust, isNull);
    });

    test('returns null when properties is missing', () {
      expect(NwsForecast.tryParse(<String, dynamic>{}), isNull);
    });

    test('returns null when periods is not a list', () {
      expect(
        NwsForecast.tryParse({
          'properties': {'periods': 'nope'}
        }),
        isNull,
      );
    });

    test('skips individual periods missing required fields instead of failing the whole parse', () {
      final json = loadFixture('forecast.json');
      final periods = (json['properties'] as Map<String, dynamic>)['periods'] as List;
      periods.add({'name': 'Broken period with no startTime/endTime'});

      final forecast = NwsForecast.tryParse(json);
      expect(forecast, isNotNull);
      expect(forecast!.periods, hasLength(4));
    });

    test('returns an empty forecast (not null) for an empty periods list', () {
      final forecast = NwsForecast.tryParse({
        'properties': {'periods': <dynamic>[]}
      });
      expect(forecast, isNotNull);
      expect(forecast!.periods, isEmpty);
    });
  });
}
