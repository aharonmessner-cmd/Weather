import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'app/app.dart';
import 'app/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loads the IANA time zone database used to render saved locations'
  // times in *their* local time rather than the device's — see
  // core/utils/location_time.dart. Synchronous and has no platform
  // dependency, so it works identically on Android/iOS/web.
  tzdata.initializeTimeZones();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const WeatherApp(),
    ),
  );
}
