import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather/core/services/allergy/allergy_client.dart';
import 'package:weather/core/services/allergy/allergy_exceptions.dart';

void main() {
  group('AllergyClient.fetchCurrent', () {
    test('requests the URL in Open-Meteo\'s documented shape, current=dust', () async {
      http.Request? captured;
      final client = AllergyClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('{"current": {"dust": 1.0}}', 200);
        }),
      );

      await client.fetchCurrent(latitude: 38.8894, longitude: -77.0352);

      expect(captured, isNotNull);
      expect(captured!.url.host, 'air-quality-api.open-meteo.com');
      expect(captured!.url.queryParameters['latitude'], '38.8894');
      expect(captured!.url.queryParameters['longitude'], '-77.0352');
      expect(captured!.url.queryParameters['current'], 'dust');
    });

    test('parses a successful response', () async {
      final client = AllergyClient(
        httpClient: MockClient((_) async => http.Response('{"current": {"dust": 42.1}}', 200)),
      );

      final response = await client.fetchCurrent(latitude: 0, longitude: 0);

      expect(response.dustMicrogramsPerCubicMeter, 42.1);
    });

    test('404 maps to AllergyServerException', () async {
      final client = AllergyClient(httpClient: MockClient((_) async => http.Response('not found', 404)));
      await expectLater(
        client.fetchCurrent(latitude: 0, longitude: 0),
        throwsA(isA<AllergyServerException>()),
      );
    });

    test('429 maps to AllergyRateLimitException', () async {
      final client = AllergyClient(httpClient: MockClient((_) async => http.Response('slow down', 429)));
      await expectLater(
        client.fetchCurrent(latitude: 0, longitude: 0),
        throwsA(isA<AllergyRateLimitException>()),
      );
    });

    test('500 maps to AllergyServerException with the status code preserved', () async {
      final client = AllergyClient(httpClient: MockClient((_) async => http.Response('error', 503)));
      try {
        await client.fetchCurrent(latitude: 0, longitude: 0);
        fail('should have thrown');
      } on AllergyServerException catch (e) {
        expect(e.statusCode, 503);
      }
    });

    test('malformed JSON maps to AllergyParseException', () async {
      final client = AllergyClient(httpClient: MockClient((_) async => http.Response('not json', 200)));
      await expectLater(
        client.fetchCurrent(latitude: 0, longitude: 0),
        throwsA(isA<AllergyParseException>()),
      );
    });

    test('a 200 response missing the current block maps to AllergyParseException', () async {
      final client = AllergyClient(httpClient: MockClient((_) async => http.Response('{}', 200)));
      await expectLater(
        client.fetchCurrent(latitude: 0, longitude: 0),
        throwsA(isA<AllergyParseException>()),
      );
    });

    test('a network failure maps to AllergyNetworkException', () async {
      final client = AllergyClient(httpClient: MockClient((_) async => throw const SocketException('offline')));
      await expectLater(
        client.fetchCurrent(latitude: 0, longitude: 0),
        throwsA(isA<AllergyNetworkException>()),
      );
    });
  });
}
