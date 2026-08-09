import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/location.dart';

void main() {
  group('Location JSON', () {
    const location = Location(
      id: 'abc-123',
      name: 'Home',
      latitude: 38.8894,
      longitude: -77.0352,
      address: '123 Main St',
      isFavorite: true,
    );

    test('round-trips through toJson/tryFromJson', () {
      final roundTripped = Location.tryFromJson(location.toJson());
      expect(roundTripped, location);
    });

    test('tryFromJson returns null when required fields are missing', () {
      expect(Location.tryFromJson({'name': 'Home'}), isNull);
      expect(Location.tryFromJson({'id': 'x', 'name': 'Home', 'latitude': 1.0}), isNull);
    });

    test('tryFromJson returns null when coordinates are the wrong type', () {
      expect(
        Location.tryFromJson({'id': 'x', 'name': 'Home', 'latitude': 'not-a-number', 'longitude': 1.0}),
        isNull,
      );
    });

    test('isFavorite defaults to false when absent', () {
      final parsed = Location.tryFromJson({'id': 'x', 'name': 'Home', 'latitude': 1.0, 'longitude': 2.0});
      expect(parsed!.isFavorite, isFalse);
    });

    test('copyWith only overrides provided fields', () {
      final updated = location.copyWith(name: 'Camp');
      expect(updated.name, 'Camp');
      expect(updated.latitude, location.latitude);
      expect(updated.id, location.id);
    });
  });
}
