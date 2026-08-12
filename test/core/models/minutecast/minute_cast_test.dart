import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/models/minutecast/minute_cast.dart';
import 'package:weather/core/models/minutecast/minute_precipitation_forecast.dart';

const _location = Location(id: 'dc', name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);

MinutePrecipitationForecast _minute(int offsetMinutes) {
  return MinutePrecipitationForecast(
    time: DateTime.utc(2026, 8, 11, 10, 38).add(Duration(minutes: offsetMinutes)),
    type: PrecipitationType.rain,
    intensityMmPerHour: 1.0,
  );
}

void main() {
  group('validUntil', () {
    test('is the last minute\'s time', () {
      final cast = MinuteCast(
        generatedAt: DateTime.utc(2026, 8, 11, 10, 38),
        location: _location,
        minutes: [_minute(0), _minute(1), _minute(59)],
        source: MinuteCastSource.pirateWeather,
      );

      expect(cast.validUntil, DateTime.utc(2026, 8, 11, 10, 38).add(const Duration(minutes: 59)));
    });

    test('is null when there are no minutes', () {
      final cast = MinuteCast(
        generatedAt: DateTime.utc(2026, 8, 11),
        location: _location,
        minutes: const [],
        source: MinuteCastSource.pirateWeather,
      );

      expect(cast.validUntil, isNull);
    });
  });

  group('isStaleAsOf', () {
    test('false within the default 20-minute threshold, true beyond it', () {
      final generatedAt = DateTime.utc(2026, 8, 11, 10, 38);
      final cast = MinuteCast(
        generatedAt: generatedAt,
        location: _location,
        minutes: [_minute(0)],
        source: MinuteCastSource.pirateWeather,
      );

      expect(cast.isStaleAsOf(generatedAt.add(const Duration(minutes: 10))), isFalse);
      expect(cast.isStaleAsOf(generatedAt.add(const Duration(minutes: 25))), isTrue);
    });
  });

  test('JSON round-trip preserves generatedAt, location, minutes, source, and uvIndex', () {
    final cast = MinuteCast(
      generatedAt: DateTime.utc(2026, 8, 11, 10, 38),
      location: _location,
      minutes: [_minute(0), _minute(1)],
      source: MinuteCastSource.pirateWeather,
      uvIndex: 6.0,
    );

    final roundTripped = MinuteCast.tryFromJson(cast.toJson());

    expect(roundTripped, isNotNull);
    expect(roundTripped!.generatedAt, cast.generatedAt);
    expect(roundTripped.location, cast.location);
    expect(roundTripped.minutes, cast.minutes);
    expect(roundTripped.source, MinuteCastSource.pirateWeather);
    expect(roundTripped.uvIndex, 6.0);
  });

  test('uvIndex round-trips as null when not reported', () {
    final cast = MinuteCast(
      generatedAt: DateTime.utc(2026, 8, 11, 10, 38),
      location: _location,
      minutes: [_minute(0)],
      source: MinuteCastSource.pirateWeather,
    );

    final roundTripped = MinuteCast.tryFromJson(cast.toJson());

    expect(roundTripped!.uvIndex, isNull);
  });

  test('tryFromJson returns null for malformed cached JSON rather than throwing', () {
    expect(MinuteCast.tryFromJson(<String, dynamic>{}), isNull);
    expect(MinuteCast.tryFromJson({'generatedAt': 'not-a-date'}), isNull);
  });
}
