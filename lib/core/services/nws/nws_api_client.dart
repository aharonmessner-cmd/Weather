import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'nws_config.dart';
import 'nws_exceptions.dart';

/// Thin HTTP layer over api.weather.gov.
///
/// This is the *only* place in the app that knows about NWS URLs, headers,
/// and HTTP status codes. It returns decoded JSON (`Map<String, dynamic>`)
/// rather than app models, since the raw-response parsing lives in
/// `core/models/nws`. Callers (the repository layer) are responsible for
/// turning that JSON into typed NWS response models and then into
/// application-level models.
///
/// NWS responses are GeoJSON-flavored: point resolution and station lists
/// hand back absolute URLs for the next request (forecast, hourly forecast,
/// observation stations, etc.) rather than IDs the client reconstructs
/// itself. This client accepts those URLs directly so it never has to guess
/// at NWS's URL structure.
class NwsApiClient {
  NwsApiClient({http.Client? httpClient, Duration? timeout})
      : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? NwsConfig.requestTimeout;

  final http.Client _httpClient;
  final Duration _timeout;

  static final Uri _alertsActiveBase = Uri.parse('${NwsConfig.baseUrl}/alerts/active');

  /// Resolves a lat/lon pair to its NWS forecast office, grid coordinates,
  /// and related endpoint URLs via `GET /points/{lat},{lon}`.
  ///
  /// The coordinate pair is joined with a literal comma rather than built
  /// via [Uri.pathSegments], since NWS expects `/points/38.8894,-77.0352`
  /// and percent-encoding the comma has been observed to cause 404s on some
  /// intermediary caches.
  Future<Map<String, dynamic>> getPoints({
    required double latitude,
    required double longitude,
  }) {
    final roundedLat = latitude.toStringAsFixed(4);
    final roundedLon = longitude.toStringAsFixed(4);
    final uri = Uri.parse('${NwsConfig.baseUrl}/points/$roundedLat,$roundedLon');
    return _getJson(uri);
  }

  /// Fetches the multi-period (day/night) text forecast for a gridpoint.
  ///
  /// [forecastUrl] should come from `properties.forecast` of a prior
  /// `getPoints` response.
  Future<Map<String, dynamic>> getForecast(String forecastUrl) {
    return _getJson(Uri.parse(forecastUrl));
  }

  /// Fetches the hour-by-hour forecast for a gridpoint.
  ///
  /// [hourlyForecastUrl] should come from `properties.forecastHourly` of a
  /// prior `getPoints` response.
  Future<Map<String, dynamic>> getHourlyForecast(String hourlyForecastUrl) {
    return _getJson(Uri.parse(hourlyForecastUrl));
  }

  /// Fetches the list of observation stations near a gridpoint, ordered by
  /// distance (nearest first) per the NWS API contract.
  ///
  /// [stationsUrl] should come from `properties.observationStations` of a
  /// prior `getPoints` response.
  Future<Map<String, dynamic>> getObservationStations(String stationsUrl) {
    return _getJson(Uri.parse(stationsUrl));
  }

  /// Fetches the most recent observation from a specific station.
  Future<Map<String, dynamic>> getLatestObservation(String stationId) {
    final uri = Uri.parse('${NwsConfig.baseUrl}/stations/$stationId/observations/latest');
    return _getJson(uri);
  }

  /// Fetches currently active alerts affecting a specific point.
  Future<Map<String, dynamic>> getActiveAlertsForPoint({
    required double latitude,
    required double longitude,
  }) {
    final uri = _alertsActiveBase.replace(queryParameters: {'point': '$latitude,$longitude'});
    return _getJson(uri);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final http.Response response;
    try {
      response = await _httpClient.get(
        uri,
        headers: {
          'User-Agent': NwsConfig.userAgent,
          'Accept': 'application/geo+json',
        },
      ).timeout(_timeout);
    } on TimeoutException {
      throw const NwsTimeoutException();
    } on SocketException {
      throw const NwsNetworkException();
    } on HttpException {
      throw const NwsNetworkException();
    } on http.ClientException {
      throw const NwsNetworkException();
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 404:
        throw const NwsNotFoundException();
      case 429:
        throw const NwsRateLimitException();
      case >= 500 && <= 599:
        throw NwsServerException(response.statusCode);
      default:
        throw NwsHttpException(response.statusCode);
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const NwsParseException();
      }
      return decoded;
    } on FormatException {
      throw const NwsParseException();
    }
  }

  void close() => _httpClient.close();
}
