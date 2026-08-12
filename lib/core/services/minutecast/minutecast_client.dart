import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/minutecast/pirate_weather_minutely.dart';
import 'minutecast_config.dart';
import 'minutecast_exceptions.dart';

/// Thin HTTP layer over Pirate Weather's `/forecast` endpoint — the only
/// place in the app that knows its URL shape and response format. Mirrors
/// `NwsApiClient`'s structure and error-mapping conventions.
class MinuteCastClient {
  MinuteCastClient({http.Client? httpClient, Duration? timeout, String? apiKey})
      : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? MinuteCastConfig.requestTimeout,
        _apiKey = apiKey ?? MinuteCastConfig.apiKey;

  final http.Client _httpClient;
  final Duration _timeout;
  final String _apiKey;

  /// Fetches the minute-by-minute precipitation nowcast for a point, plus
  /// `currently.uvIndex` (see [PirateWeatherResponse.uvIndex]).
  ///
  /// `hourly`/`daily`/`alerts` are still excluded — this app never uses
  /// Pirate Weather for forecasts or alerts, only `minutely` (precipitation
  /// nowcast) and `currently` (UV Index), so there's no reason to pay for
  /// the rest of that payload. Keeping `currently` in the same request
  /// means UV Index never needs a second API call.
  Future<PirateWeatherResponse> fetchMinutely({
    required double latitude,
    required double longitude,
  }) async {
    if (_apiKey.isEmpty) throw const MinuteCastNotConfiguredException();

    final uri = Uri.parse('${MinuteCastConfig.baseUrl}/$_apiKey/$latitude,$longitude').replace(
      queryParameters: {
        'units': 'si',
        'exclude': 'hourly,daily,alerts,flags',
      },
    );

    final http.Response response;
    try {
      response = await _httpClient.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const MinuteCastTimeoutException();
    } on SocketException {
      throw const MinuteCastNetworkException();
    } on HttpException {
      throw const MinuteCastNetworkException();
    } on http.ClientException {
      throw const MinuteCastNetworkException();
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 429:
        throw const MinuteCastRateLimitException();
      case >= 500 && <= 599:
        throw MinuteCastServerException(response.statusCode);
      default:
        throw MinuteCastServerException(
          response.statusCode,
          'Unexpected response from the precipitation nowcast service.',
        );
    }

    final Map<String, dynamic> decoded;
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) throw const MinuteCastParseException();
      decoded = body;
    } on FormatException {
      throw const MinuteCastParseException();
    }

    final parsed = PirateWeatherResponse.tryParse(decoded);
    if (parsed == null) throw const MinuteCastParseException();
    return parsed;
  }

  void close() => _httpClient.close();
}
