import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/geocode_result.dart';
import 'geocoding_config.dart';
import 'geocoding_exceptions.dart';

/// Thin HTTP layer over Nominatim's `/search` endpoint — the only place in
/// the app that knows about Nominatim's request/response shape. Turns its
/// address-component breakdown into clean, disambiguated [GeocodeResult]s;
/// callers never see Nominatim's raw `display_name` or JSON.
class NominatimGeocodingClient {
  NominatimGeocodingClient({http.Client? httpClient, Duration? timeout})
      : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? GeocodingConfig.requestTimeout;

  final http.Client _httpClient;
  final Duration _timeout;

  /// Searches for places matching [query] (a city name, "City, ST", or a
  /// ZIP/postal code). Returns an empty list for "no results" — callers
  /// distinguish "no results" from "search failed" by whether this throws.
  Future<List<GeocodeResult>> search(String query) async {
    final uri = Uri.parse('${GeocodingConfig.baseUrl}/search').replace(queryParameters: {
      'q': query,
      'format': 'jsonv2',
      'addressdetails': '1',
      'countrycodes': GeocodingConfig.countryCodes,
      'limit': '${GeocodingConfig.resultLimit}',
    });

    final http.Response response;
    try {
      response = await _httpClient.get(
        uri,
        headers: {'User-Agent': GeocodingConfig.userAgent},
      ).timeout(_timeout);
    } on TimeoutException {
      throw const GeocodingTimeoutException();
    } on SocketException {
      throw const GeocodingNetworkException();
    } on HttpException {
      throw const GeocodingNetworkException();
    } on http.ClientException {
      throw const GeocodingNetworkException();
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 429:
        throw const GeocodingRateLimitException();
      case >= 500 && <= 599:
        throw GeocodingServerException(response.statusCode);
      default:
        throw GeocodingServerException(response.statusCode, 'Unexpected response from the location search service.');
    }

    final List<dynamic> decoded;
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! List) throw const GeocodingParseException();
      decoded = body;
    } on FormatException {
      throw const GeocodingParseException();
    }

    final places = decoded.whereType<Map<String, dynamic>>().map(_parsePlace).whereType<_RawPlace>().toList();
    return _toResults(places);
  }

  void close() => _httpClient.close();

  static _RawPlace? _parsePlace(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['lat']}');
    final lon = double.tryParse('${json['lon']}');
    if (lat == null || lon == null) return null;

    final address = json['address'];
    final addr = address is Map ? address : const {};

    final name = _firstNonEmpty([
      addr['city'],
      addr['town'],
      addr['village'],
      addr['hamlet'],
      addr['municipality'],
      addr['suburb'],
      json['name'],
    ]);
    if (name == null) return null;

    return _RawPlace(
      latitude: lat,
      longitude: lon,
      name: name,
      county: _asNonEmptyString(addr['county']),
      state: _asNonEmptyString(addr['state']),
      country: _asNonEmptyString(addr['country']),
    );
  }

  /// Builds the final, clean result list: a short "State, Country" subtitle
  /// by default, upgraded to "County, State" for every entry whose [name]
  /// is shared by another result in this same list — e.g. three
  /// "Middletown" results (NY, NJ, CT) become "Orange County, New York",
  /// "Monmouth County, New Jersey", "Middlesex County, Connecticut" rather
  /// than relying on the state alone to read as different rows.
  static List<GeocodeResult> _toResults(List<_RawPlace> places) {
    final nameCounts = <String, int>{};
    for (final place in places) {
      final key = place.name.toLowerCase();
      nameCounts[key] = (nameCounts[key] ?? 0) + 1;
    }

    return places.map((place) {
      final ambiguous = (nameCounts[place.name.toLowerCase()] ?? 0) > 1 && place.county != null;
      final subtitleParts = ambiguous ? [place.county, place.state] : [place.state, place.country];
      final subtitle = subtitleParts.nonNulls.join(', ');
      return GeocodeResult(
        latitude: place.latitude,
        longitude: place.longitude,
        name: place.name,
        subtitle: subtitle.isEmpty ? (place.country ?? '') : subtitle,
      );
    }).toList();
  }

  static String? _asNonEmptyString(dynamic value) {
    if (value is! String) return null;
    return value.isEmpty ? null : value;
  }

  static String? _firstNonEmpty(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final str = _asNonEmptyString(candidate);
      if (str != null) return str;
    }
    return null;
  }
}

class _RawPlace {
  const _RawPlace({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.county,
    required this.state,
    required this.country,
  });

  final double latitude;
  final double longitude;
  final String name;
  final String? county;
  final String? state;
  final String? country;
}
