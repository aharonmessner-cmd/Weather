import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/repositories/minutecast_repository.dart';
import '../core/repositories/weather_repository.dart';
import '../core/repositories/zmanim_repository.dart';
import '../core/services/cache/minutecast_cache.dart';
import '../core/services/cache/weather_cache.dart';
import '../core/services/cache/zmanim_cache.dart';
import '../core/services/geocoding/nominatim_geocoding_client.dart';
import '../core/services/location/device_location_service.dart';
import '../core/services/location/location_naming_service.dart';
import '../core/services/location/location_store.dart';
import '../core/services/minutecast/minutecast_client.dart';
import '../core/services/nws/nws_api_client.dart';
import '../core/services/zmanim/zmanim_client.dart';

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

final deviceLocationServiceProvider = Provider<DeviceLocationService>((ref) {
  return DeviceLocationService();
});

/// Resolves a display name for raw coordinates via NWS `/points` — reuses
/// the same [NwsApiClient] the weather pipeline already depends on, rather
/// than a second geocoding lookup just for "Use My Location" naming.
final locationNamingServiceProvider = Provider<LocationNamingService>((ref) {
  return LocationNamingService(ref.watch(nwsApiClientProvider));
});

final geocodingClientProvider = Provider<NominatimGeocodingClient>((ref) {
  final client = NominatimGeocodingClient();
  ref.onDispose(client.close);
  return client;
});

final minuteCastClientProvider = Provider<MinuteCastClient>((ref) {
  final client = MinuteCastClient();
  ref.onDispose(client.close);
  return client;
});

final minuteCastCacheProvider = Provider<MinuteCastCache>((ref) {
  return MinuteCastCache(ref.watch(sharedPreferencesProvider));
});

final minuteCastRepositoryProvider = Provider<MinuteCastRepository>((ref) {
  return PirateWeatherMinuteCastRepository(
    client: ref.watch(minuteCastClientProvider),
    cache: ref.watch(minuteCastCacheProvider),
  );
});

final zmanimClientProvider = Provider<ZmanimClient>((ref) {
  final client = ZmanimClient();
  ref.onDispose(client.close);
  return client;
});

final zmanimCacheProvider = Provider<ZmanimCache>((ref) {
  return ZmanimCache(ref.watch(sharedPreferencesProvider));
});

final zmanimRepositoryProvider = Provider<ZmanimRepository>((ref) {
  return HebcalZmanimRepository(
    client: ref.watch(zmanimClientProvider),
    cache: ref.watch(zmanimCacheProvider),
  );
});
