import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/utils/sun_times.dart';

void main() {
  group('computeSunTimes', () {
    const washingtonDC = (latitude: 38.8894, longitude: -77.0352);

    test('sunrise is before sunset on an ordinary day', () {
      final times = computeSunTimes(
        latitude: washingtonDC.latitude,
        longitude: washingtonDC.longitude,
        date: DateTime.utc(2026, 3, 15),
      );
      expect(times.sunrise, isNotNull);
      expect(times.sunset, isNotNull);
      expect(times.sunrise!.isBefore(times.sunset!), isTrue);
    });

    test('day length is longer at the summer solstice than the winter solstice', () {
      final summer = computeSunTimes(
        latitude: washingtonDC.latitude,
        longitude: washingtonDC.longitude,
        date: DateTime.utc(2026, 6, 21),
      );
      final winter = computeSunTimes(
        latitude: washingtonDC.latitude,
        longitude: washingtonDC.longitude,
        date: DateTime.utc(2026, 12, 21),
      );

      final summerLength = summer.sunset!.difference(summer.sunrise!);
      final winterLength = winter.sunset!.difference(winter.sunrise!);

      expect(summerLength, greaterThan(winterLength));
      // Sanity bounds: DC summer days run ~14-15h, winter ~9-10h.
      expect(summerLength.inMinutes, inInclusiveRange(13 * 60, 16 * 60));
      expect(winterLength.inMinutes, inInclusiveRange(8 * 60, 11 * 60));
    });

    test('day length at the equator stays close to 12 hours year-round', () {
      final juneEquator = computeSunTimes(latitude: 0, longitude: 0, date: DateTime.utc(2026, 6, 21));
      final decemberEquator = computeSunTimes(latitude: 0, longitude: 0, date: DateTime.utc(2026, 12, 21));

      for (final times in [juneEquator, decemberEquator]) {
        final length = times.sunset!.difference(times.sunrise!);
        expect(length.inMinutes, closeTo(12 * 60, 20));
      }
    });

    test('sunrise and sunset are roughly symmetric around solar noon', () {
      final times = computeSunTimes(
        latitude: washingtonDC.latitude,
        longitude: washingtonDC.longitude,
        date: DateTime.utc(2026, 9, 1),
      );
      final solarNoon = times.sunrise!.add(times.sunset!.difference(times.sunrise!) ~/ 2);
      final morningHalf = solarNoon.difference(times.sunrise!);
      final afternoonHalf = times.sunset!.difference(solarNoon);
      expect((morningHalf - afternoonHalf).inMinutes.abs(), lessThan(2));
    });

    test('returns null sunrise/sunset for polar night in winter at high latitude', () {
      final times = computeSunTimes(latitude: 78, longitude: 0, date: DateTime.utc(2026, 12, 21));
      expect(times.sunrise, isNull);
      expect(times.sunset, isNull);
    });

    test('returns null sunrise/sunset for the midnight sun in summer at high latitude', () {
      final times = computeSunTimes(latitude: 78, longitude: 0, date: DateTime.utc(2026, 6, 21));
      expect(times.sunrise, isNull);
      expect(times.sunset, isNull);
    });
  });
}
