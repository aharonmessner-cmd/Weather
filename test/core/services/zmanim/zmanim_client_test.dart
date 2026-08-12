import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather/core/models/zmanim/hebcal_zman_field.dart';
import 'package:weather/core/services/zmanim/zmanim_client.dart';
import 'package:weather/core/services/zmanim/zmanim_exceptions.dart';

void main() {
  group('ZmanimClient.fetchZmanim', () {
    test('requests the URL in Hebcal\'s documented shape (cfg=json, lat/lon/tzid/date)', () async {
      http.Request? captured;
      final client = ZmanimClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('{"times": {"sunrise": "2026-08-11T06:08:00-04:00"}}', 200);
        }),
      );

      await client.fetchZmanim(latitude: 38.8894, longitude: -77.0352, timeZone: 'America/New_York', date: '2026-08-11');

      expect(captured, isNotNull);
      expect(captured!.url.host, 'www.hebcal.com');
      expect(captured!.url.path, '/zmanim');
      expect(captured!.url.queryParameters['cfg'], 'json');
      expect(captured!.url.queryParameters['latitude'], '38.8894');
      expect(captured!.url.queryParameters['longitude'], '-77.0352');
      expect(captured!.url.queryParameters['tzid'], 'America/New_York');
      expect(captured!.url.queryParameters['date'], '2026-08-11');
    });

    test('parses a successful response', () async {
      final client = ZmanimClient(
        httpClient: MockClient((_) async => http.Response(
              '{"times": {"sunrise": "2026-08-11T06:08:00-04:00", "chatzot": "2026-08-11T13:03:00-04:00"}}',
              200,
            )),
      );

      final response = await client.fetchZmanim(
        latitude: 38.8894,
        longitude: -77.0352,
        timeZone: 'America/New_York',
        date: '2026-08-11',
      );

      expect(response.times[HebcalZmanField.sunrise], DateTime.parse('2026-08-11T06:08:00-04:00'));
      expect(response.times[HebcalZmanField.chatzot], DateTime.parse('2026-08-11T13:03:00-04:00'));
    });

    test('404 maps to ZmanimServerException', () async {
      final client = ZmanimClient(httpClient: MockClient((_) async => http.Response('not found', 404)));
      await expectLater(
        client.fetchZmanim(latitude: 0, longitude: 0, timeZone: 'UTC', date: '2026-08-11'),
        throwsA(isA<ZmanimServerException>()),
      );
    });

    test('429 maps to ZmanimRateLimitException', () async {
      final client = ZmanimClient(httpClient: MockClient((_) async => http.Response('slow down', 429)));
      await expectLater(
        client.fetchZmanim(latitude: 0, longitude: 0, timeZone: 'UTC', date: '2026-08-11'),
        throwsA(isA<ZmanimRateLimitException>()),
      );
    });

    test('500 maps to ZmanimServerException with the status code preserved', () async {
      final client = ZmanimClient(httpClient: MockClient((_) async => http.Response('error', 503)));
      try {
        await client.fetchZmanim(latitude: 0, longitude: 0, timeZone: 'UTC', date: '2026-08-11');
        fail('should have thrown');
      } on ZmanimServerException catch (e) {
        expect(e.statusCode, 503);
      }
    });

    test('malformed JSON maps to ZmanimParseException', () async {
      final client = ZmanimClient(httpClient: MockClient((_) async => http.Response('not json', 200)));
      await expectLater(
        client.fetchZmanim(latitude: 0, longitude: 0, timeZone: 'UTC', date: '2026-08-11'),
        throwsA(isA<ZmanimParseException>()),
      );
    });

    test('a 200 response with no usable times maps to ZmanimParseException', () async {
      final client = ZmanimClient(httpClient: MockClient((_) async => http.Response('{"date": "2026-08-11"}', 200)));
      await expectLater(
        client.fetchZmanim(latitude: 0, longitude: 0, timeZone: 'UTC', date: '2026-08-11'),
        throwsA(isA<ZmanimParseException>()),
      );
    });

    test('a network failure maps to ZmanimNetworkException', () async {
      final client = ZmanimClient(httpClient: MockClient((_) async => throw const SocketException('offline')));
      await expectLater(
        client.fetchZmanim(latitude: 0, longitude: 0, timeZone: 'UTC', date: '2026-08-11'),
        throwsA(isA<ZmanimNetworkException>()),
      );
    });
  });
}
