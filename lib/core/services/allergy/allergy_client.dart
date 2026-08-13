import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/allergy/open_meteo_air_quality.dart';
import 'allergy_config.dart';
import 'allergy_exceptions.dart';

/// Thin HTTP layer over Open-Meteo's Air Quality `/v1/air-quality`
/// endpoint — the only place in the app that knows its URL shape and
/// response format. Mirrors `MinuteCastClient`'s structure and
/// error-mapping conventions.
///
/// Open-Meteo's Air Quality API is free and keyless (no signup, no
/// `--dart-define` needed), so unlike `MinuteCastClient` there is no
/// "not configured" state here -- a location's coordinates are always
/// enough to make the request.
class AllergyClient {
  AllergyClient({http.Client? httpClient, Duration? timeout})
      : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? AllergyConfig.requestTimeout;

  final http.Client _httpClient;
  final Duration _timeout;

  /// Fetches current surface dust concentration for a point.
  Future<OpenMeteoAirQualityResponse> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(AllergyConfig.baseUrl).replace(
      queryParameters: {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'current': 'dust',
      },
    );

    final http.Response response;
    try {
      response = await _httpClient.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const AllergyTimeoutException();
    } on SocketException {
      throw const AllergyNetworkException();
    } on HttpException {
      throw const AllergyNetworkException();
    } on http.ClientException {
      throw const AllergyNetworkException();
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 429:
        throw const AllergyRateLimitException();
      case >= 500 && <= 599:
        throw AllergyServerException(response.statusCode);
      default:
        throw AllergyServerException(
          response.statusCode,
          'Unexpected response from the air quality service.',
        );
    }

    final Map<String, dynamic> decoded;
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) throw const AllergyParseException();
      decoded = body;
    } on FormatException {
      throw const AllergyParseException();
    }

    final parsed = OpenMeteoAirQualityResponse.tryParse(decoded);
    if (parsed == null) throw const AllergyParseException();
    return parsed;
  }

  void close() => _httpClient.close();
}
