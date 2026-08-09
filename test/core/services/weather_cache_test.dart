import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/core/models/current_conditions.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/models/weather_data.dart';
import 'package:weather/core/services/cache/weather_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const location = Location(id: 'home', name: 'Home', latitude: 1, longitude: 2);

  WeatherData sample() => WeatherData(
        location: location,
        current: const CurrentConditions(temperatureFahrenheit: 72),
        fetchedAt: DateTime.utc(2026, 8, 9, 12),
      );

  group('WeatherCache', () {
    test('read returns null when nothing has been cached', () async {
      SharedPreferences.setMockInitialValues({});
      final cache = WeatherCache(await SharedPreferences.getInstance());

      expect(await cache.read('home'), isNull);
    });

    test('write then read returns an equivalent snapshot', () async {
      SharedPreferences.setMockInitialValues({});
      final cache = WeatherCache(await SharedPreferences.getInstance());

      await cache.write('home', sample());
      final result = await cache.read('home');

      expect(result, isNotNull);
      expect(result!.location, location);
      expect(result.current.temperatureFahrenheit, 72);
    });

    test('caches for different locations do not clobber each other', () async {
      SharedPreferences.setMockInitialValues({});
      final cache = WeatherCache(await SharedPreferences.getInstance());
      const otherLocation = Location(id: 'school', name: 'School', latitude: 3, longitude: 4);

      await cache.write('home', sample());
      await cache.write('school', sample().copyWith(location: otherLocation));

      expect((await cache.read('home'))!.location.id, 'home');
      expect((await cache.read('school'))!.location.id, 'school');
    });

    test('clear removes only the specified location', () async {
      SharedPreferences.setMockInitialValues({});
      final cache = WeatherCache(await SharedPreferences.getInstance());

      await cache.write('home', sample());
      await cache.clear('home');

      expect(await cache.read('home'), isNull);
    });

    test('read returns null for corrupted JSON instead of throwing', () async {
      SharedPreferences.setMockInitialValues({'weather_cache_v1_home': 'not valid json {'});
      final cache = WeatherCache(await SharedPreferences.getInstance());

      expect(await cache.read('home'), isNull);
    });
  });
}
