import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/current_conditions.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/models/weather_data.dart';

void main() {
  final location = const Location(id: 'home', name: 'Home', latitude: 1, longitude: 2);

  group('WeatherData JSON round-trip', () {
    test('preserves nested collections through toJson/tryFromJson', () {
      final data = WeatherData(
        location: location,
        current: const CurrentConditions(temperatureFahrenheit: 72),
        fetchedAt: DateTime.utc(2026, 8, 9, 12),
      );

      final roundTripped = WeatherData.tryFromJson(data.toJson());
      expect(roundTripped, isNotNull);
      expect(roundTripped!.location, location);
      expect(roundTripped.current.temperatureFahrenheit, 72);
      expect(roundTripped.fetchedAt, data.fetchedAt);
      expect(roundTripped.hourly, isEmpty);
      expect(roundTripped.alerts, isEmpty);
    });

    test('returns null for malformed cached JSON rather than throwing', () {
      expect(WeatherData.tryFromJson(<String, dynamic>{}), isNull);
      expect(WeatherData.tryFromJson({'location': location.toJson()}), isNull);
    });

    test('round-trips timeZone through toJson/tryFromJson', () {
      final data = WeatherData(
        location: location,
        current: const CurrentConditions(temperatureFahrenheit: 72),
        fetchedAt: DateTime.utc(2026, 8, 9, 12),
        timeZone: 'America/New_York',
      );

      final roundTripped = WeatherData.tryFromJson(data.toJson());
      expect(roundTripped!.timeZone, 'America/New_York');
    });

    test('timeZone is null (not a crash) for cached JSON from before this field existed', () {
      final data = WeatherData(
        location: location,
        current: const CurrentConditions(temperatureFahrenheit: 72),
        fetchedAt: DateTime.utc(2026, 8, 9, 12),
      );
      final json = data.toJson()..remove('timeZone');

      final roundTripped = WeatherData.tryFromJson(json);
      expect(roundTripped!.timeZone, isNull);
    });
  });

  group('isStaleAsOf', () {
    test('is false just after fetching, true well past the threshold', () {
      final fetchedAt = DateTime(2026, 8, 9, 12);
      final data = WeatherData(
        location: location,
        current: const CurrentConditions(),
        fetchedAt: fetchedAt,
      );

      expect(data.isStaleAsOf(fetchedAt.add(const Duration(minutes: 5))), isFalse);
      expect(data.isStaleAsOf(fetchedAt.add(const Duration(hours: 2))), isTrue);
    });
  });
}
