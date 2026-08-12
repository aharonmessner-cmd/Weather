import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/zmanim/hebcal_zmanim_response.dart';
import 'zmanim_api_config.dart';
import 'zmanim_exceptions.dart';

/// Thin HTTP layer over Hebcal's `/zmanim` endpoint — the only place in
/// the app that knows its URL shape and response format. Mirrors
/// `MinuteCastClient`'s structure and error-mapping conventions.
class ZmanimClient {
  ZmanimClient({http.Client? httpClient, Duration? timeout})
      : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? ZmanimApiConfig.requestTimeout;

  final http.Client _httpClient;
  final Duration _timeout;

  /// Fetches zmanim for one calendar day at a point.
  ///
  /// [date] is `YYYY-MM-DD` for the *location's* calendar date — callers
  /// must resolve "today" in the location's time zone before calling
  /// this (see `ZmanimRepository`), never the device's local date.
  /// [timeZone] is the location's IANA identifier; Hebcal requires it
  /// alongside bare lat/lon so it can compute times in the right zone
  /// without a secondary geocoding lookup.
  Future<HebcalZmanimResponse> fetchZmanim({
    required double latitude,
    required double longitude,
    required String timeZone,
    required String date,
  }) async {
    final uri = Uri.parse(ZmanimApiConfig.baseUrl).replace(queryParameters: {
      'cfg': 'json',
      'latitude': '$latitude',
      'longitude': '$longitude',
      'tzid': timeZone,
      'date': date,
    });

    final http.Response response;
    try {
      response = await _httpClient.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const ZmanimTimeoutException();
    } on SocketException {
      throw const ZmanimNetworkException();
    } on HttpException {
      throw const ZmanimNetworkException();
    } on http.ClientException {
      throw const ZmanimNetworkException();
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 429:
        throw const ZmanimRateLimitException();
      case >= 500 && <= 599:
        throw ZmanimServerException(response.statusCode);
      default:
        throw ZmanimServerException(response.statusCode, 'Unexpected response from the Zmanim service.');
    }

    final Map<String, dynamic> decoded;
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) throw const ZmanimParseException();
      decoded = body;
    } on FormatException {
      throw const ZmanimParseException();
    }

    final parsed = HebcalZmanimResponse.tryParse(decoded);
    if (parsed == null) throw const ZmanimParseException();
    return parsed;
  }

  void close() => _httpClient.close();
}
