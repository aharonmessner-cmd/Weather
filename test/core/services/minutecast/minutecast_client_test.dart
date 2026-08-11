import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather/core/services/minutecast/minutecast_client.dart';
import 'package:weather/core/services/minutecast/minutecast_exceptions.dart';

void main() {
  group('MinuteCastClient.fetchMinutely', () {
    test('throws MinuteCastNotConfiguredException when no API key is set, without making a request', () async {
      var requested = false;
      final client = MinuteCastClient(
        apiKey: '',
        httpClient: MockClient((_) async {
          requested = true;
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        client.fetchMinutely(latitude: 38.8894, longitude: -77.0352),
        throwsA(isA<MinuteCastNotConfiguredException>()),
      );
      expect(requested, isFalse);
    });

    test('requests the URL in Pirate Weather\'s documented shape, si units, minutely only', () async {
      http.Request? captured;
      final client = MinuteCastClient(
        apiKey: 'test-key',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('{"minutely": {"data": [{"time": 1755000000}]}}', 200);
        }),
      );

      await client.fetchMinutely(latitude: 38.8894, longitude: -77.0352);

      expect(captured, isNotNull);
      expect(captured!.url.path, '/forecast/test-key/38.8894,-77.0352');
      expect(captured!.url.queryParameters['units'], 'si');
      expect(captured!.url.queryParameters['exclude'], contains('currently'));
    });

    test('parses a successful response into minutes', () async {
      final client = MinuteCastClient(
        apiKey: 'test-key',
        httpClient: MockClient((_) async => http.Response(
              '{"minutely": {"data": [{"time": 1755000000, "precipIntensity": 1.0, "precipType": "rain"}]}}',
              200,
            )),
      );

      final response = await client.fetchMinutely(latitude: 38.8894, longitude: -77.0352);

      expect(response.minutes, hasLength(1));
      expect(response.minutes.single.precipType, 'rain');
    });

    test('404 maps to MinuteCastServerException', () async {
      final client = MinuteCastClient(
        apiKey: 'test-key',
        httpClient: MockClient((_) async => http.Response('not found', 404)),
      );
      await expectLater(
        client.fetchMinutely(latitude: 0, longitude: 0),
        throwsA(isA<MinuteCastServerException>()),
      );
    });

    test('429 maps to MinuteCastRateLimitException', () async {
      final client = MinuteCastClient(
        apiKey: 'test-key',
        httpClient: MockClient((_) async => http.Response('slow down', 429)),
      );
      await expectLater(
        client.fetchMinutely(latitude: 0, longitude: 0),
        throwsA(isA<MinuteCastRateLimitException>()),
      );
    });

    test('500 maps to MinuteCastServerException with the status code preserved', () async {
      final client = MinuteCastClient(
        apiKey: 'test-key',
        httpClient: MockClient((_) async => http.Response('error', 503)),
      );
      try {
        await client.fetchMinutely(latitude: 0, longitude: 0);
        fail('should have thrown');
      } on MinuteCastServerException catch (e) {
        expect(e.statusCode, 503);
      }
    });

    test('malformed JSON maps to MinuteCastParseException', () async {
      final client = MinuteCastClient(
        apiKey: 'test-key',
        httpClient: MockClient((_) async => http.Response('not json', 200)),
      );
      await expectLater(
        client.fetchMinutely(latitude: 0, longitude: 0),
        throwsA(isA<MinuteCastParseException>()),
      );
    });

    test('a 200 response with no usable minutely data maps to MinuteCastParseException', () async {
      final client = MinuteCastClient(
        apiKey: 'test-key',
        httpClient: MockClient((_) async => http.Response('{"currently": {}}', 200)),
      );
      await expectLater(
        client.fetchMinutely(latitude: 0, longitude: 0),
        throwsA(isA<MinuteCastParseException>()),
      );
    });

    test('a network failure maps to MinuteCastNetworkException', () async {
      final client = MinuteCastClient(
        apiKey: 'test-key',
        httpClient: MockClient((_) async => throw const SocketException('offline')),
      );
      await expectLater(
        client.fetchMinutely(latitude: 0, longitude: 0),
        throwsA(isA<MinuteCastNetworkException>()),
      );
    });
  });
}
