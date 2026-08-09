import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/services/location/location_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationStore', () {
    test('readAll returns an empty list when nothing is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocationStore(await SharedPreferences.getInstance());

      expect(store.readAll(), isEmpty);
    });

    test('writeAll then readAll round-trips the saved locations in order', () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocationStore(await SharedPreferences.getInstance());
      const locations = [
        Location(id: '1', name: 'Home', latitude: 1, longitude: 2, isFavorite: true),
        Location(id: '2', name: 'School', latitude: 3, longitude: 4),
      ];

      await store.writeAll(locations);

      expect(store.readAll(), locations);
    });

    test('readAll returns an empty list for corrupted JSON instead of throwing', () async {
      SharedPreferences.setMockInitialValues({'saved_locations_v1': 'not valid json'});
      final store = LocationStore(await SharedPreferences.getInstance());

      expect(store.readAll(), isEmpty);
    });

    test('readAll skips malformed entries but keeps valid ones', () async {
      SharedPreferences.setMockInitialValues({
        'saved_locations_v1': '[{"id":"1","name":"Home","latitude":1,"longitude":2}, {"name":"missing id/coords"}]',
      });
      final store = LocationStore(await SharedPreferences.getInstance());

      final result = store.readAll();
      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });
  });
}
