import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather/core/services/nws/nws_api_client.dart';
import 'package:weather/core/services/nws/nws_config.dart';
import 'package:weather/core/services/nws/nws_exceptions.dart';

void main() {
  group('NwsApiClient User-Agent', () {
    test('every request includes the configured User-Agent header', () async {
      http.Request? captured;
      final client = NwsApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('{"properties": {}}', 200);
        }),
      );

      await client.getForecast('https://api.weather.gov/gridpoints/LWX/97,71/forecast');

      expect(captured, isNotNull);
      expect(captured!.headers['User-Agent'], NwsConfig.userAgent);
      // NWS's documented convention: "(app identifier, contact info)".
      expect(NwsConfig.userAgent, matches(RegExp(r'^\(.+, .+\)$')));
    });
  });

  group('NwsApiClient error handling', () {
    test('404 maps to NwsNotFoundException', () async {
      final client = NwsApiClient(httpClient: MockClient((_) async => http.Response('not found', 404)));
      await expectLater(
        client.getForecast('https://api.weather.gov/x'),
        throwsA(isA<NwsNotFoundException>()),
      );
    });

    test('429 maps to NwsRateLimitException', () async {
      final client = NwsApiClient(httpClient: MockClient((_) async => http.Response('slow down', 429)));
      await expectLater(
        client.getForecast('https://api.weather.gov/x'),
        throwsA(isA<NwsRateLimitException>()),
      );
    });

    test('5xx maps to NwsServerException carrying the status code', () async {
      final client = NwsApiClient(httpClient: MockClient((_) async => http.Response('boom', 503)));
      try {
        await client.getForecast('https://api.weather.gov/x');
        fail('expected NwsServerException');
      } on NwsServerException catch (e) {
        expect(e.statusCode, 503);
      }
    });

    test('an unexpected status code maps to NwsHttpException carrying it', () async {
      final client = NwsApiClient(httpClient: MockClient((_) async => http.Response('teapot', 418)));
      try {
        await client.getForecast('https://api.weather.gov/x');
        fail('expected NwsHttpException');
      } on NwsHttpException catch (e) {
        expect(e.statusCode, 418);
      }
    });

    test('a timeout maps to NwsTimeoutException', () async {
      final client = NwsApiClient(
        timeout: const Duration(milliseconds: 20),
        httpClient: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return http.Response('{}', 200);
        }),
      );
      await expectLater(
        client.getForecast('https://api.weather.gov/x'),
        throwsA(isA<NwsTimeoutException>()),
      );
    });

    test('a thrown ClientException maps to NwsNetworkException', () async {
      final client = NwsApiClient(
        httpClient: MockClient((_) async => throw http.ClientException('connection reset')),
      );
      await expectLater(
        client.getForecast('https://api.weather.gov/x'),
        throwsA(isA<NwsNetworkException>()),
      );
    });

    test('malformed JSON maps to NwsParseException', () async {
      final client = NwsApiClient(httpClient: MockClient((_) async => http.Response('not json {', 200)));
      await expectLater(
        client.getForecast('https://api.weather.gov/x'),
        throwsA(isA<NwsParseException>()),
      );
    });

    test('valid JSON that is not an object maps to NwsParseException', () async {
      final client = NwsApiClient(httpClient: MockClient((_) async => http.Response('[1, 2, 3]', 200)));
      await expectLater(
        client.getForecast('https://api.weather.gov/x'),
        throwsA(isA<NwsParseException>()),
      );
    });
  });

  group('NwsApiClient debug logging', () {
    test('logs nothing when debugLogging is off (the default)', () async {
      final logs = <String>[];
      final client = NwsApiClient(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
        onDebugLog: logs.add,
      );

      await client.getForecast('https://api.weather.gov/x');

      expect(logs, isEmpty);
    });

    test('logs the endpoint and status code when enabled', () async {
      final logs = <String>[];
      final client = NwsApiClient(
        debugLogging: true,
        httpClient: MockClient((_) async => http.Response('{}', 200)),
        onDebugLog: logs.add,
      );

      await client.getForecast('https://api.weather.gov/gridpoints/LWX/97,71/forecast');

      expect(logs, hasLength(1));
      expect(logs.single, contains('https://api.weather.gov/gridpoints/LWX/97,71/forecast'));
      expect(logs.single, contains('200'));
    });

    test('logs an error label instead of a status code when the request fails outright', () async {
      final logs = <String>[];
      final client = NwsApiClient(
        debugLogging: true,
        httpClient: MockClient((_) async => throw http.ClientException('reset')),
        onDebugLog: logs.add,
      );

      await expectLater(client.getForecast('https://api.weather.gov/x'), throwsA(isA<NwsNetworkException>()));

      expect(logs, hasLength(1));
      expect(logs.single, contains('network error'));
    });

    test('never logs the User-Agent header or its contact email', () async {
      final logs = <String>[];
      final client = NwsApiClient(
        debugLogging: true,
        httpClient: MockClient((_) async => http.Response('{}', 200)),
        onDebugLog: logs.add,
      );

      await client.getForecast('https://api.weather.gov/x');

      final combined = logs.join('\n');
      expect(combined, isNot(contains(NwsConfig.contactEmail)));
      expect(combined.toLowerCase(), isNot(contains('user-agent')));
    });

    test('never logs response body content', () async {
      final logs = <String>[];
      final client = NwsApiClient(
        debugLogging: true,
        httpClient: MockClient((_) async => http.Response('{"secretMarker": "should-not-appear"}', 200)),
        onDebugLog: logs.add,
      );

      await client.getForecast('https://api.weather.gov/x');

      expect(logs.join('\n'), isNot(contains('should-not-appear')));
    });
  });
}
