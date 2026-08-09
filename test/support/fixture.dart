import 'dart:convert';
import 'dart:io';

/// Loads a JSON fixture from `test/fixtures/` as a decoded map.
///
/// Keeping unit tests off live NWS requests: these fixtures are hand-copied
/// (based on documented NWS API response shapes) samples of the endpoints
/// the app talks to, so parsing logic can be exercised deterministically.
Map<String, dynamic> loadFixture(String name) {
  final file = File('test/fixtures/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

String loadFixtureRaw(String name) {
  return File('test/fixtures/$name').readAsStringSync();
}
