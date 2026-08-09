import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/repositories/weather_repository.dart';
import '../core/services/cache/weather_cache.dart';
import '../core/services/location/location_store.dart';
import '../core/services/nws/nws_api_client.dart';

/// Overridden in `main()` with the real instance once it's been awaited —
/// every other provider in the app depends on it transitively, so nothing
/// can read from local storage before that override is in place.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

final nwsApiClientProvider = Provider<NwsApiClient>((ref) {
  final client = NwsApiClient();
  ref.onDispose(client.close);
  return client;
});

final weatherCacheProvider = Provider<WeatherCache>((ref) {
  return WeatherCache(ref.watch(sharedPreferencesProvider));
});

final locationStoreProvider = Provider<LocationStore>((ref) {
  return LocationStore(ref.watch(sharedPreferencesProvider));
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return NwsWeatherRepository(
    client: ref.watch(nwsApiClientProvider),
    cache: ref.watch(weatherCacheProvider),
  );
});
