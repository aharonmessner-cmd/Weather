# Weather

A private, cross-platform weather app (iOS, Android, web) built with Flutter,
backed entirely by the [National Weather Service API](https://api.weather.gov).
Built for personal use by a small group of friends — no accounts, no backend,
no analytics.

## Features (V1)

- Current conditions, hourly timeline, multi-day forecast, and station
  observations (wind, humidity, dew point, visibility, pressure) for any
  number of saved locations.
- Active NWS alerts, color-coded by severity, with a full-detail view.
- Local caching: the last successful forecast is shown immediately on
  launch and while offline, clearly marked as stale when it is.
- Responsive layouts: single-column on phones, a two-column dashboard grid
  on tablets/desktop, with a bottom nav bar on mobile and a side rail on
  larger screens.
- Light and dark themes.

## Architecture

```
lib/
  app/            App shell, navigation, theming, top-level providers
  core/
    models/       App-level models (Location, WeatherData, ...) and the
                   nws/ subfolder with raw NWS response models
    services/
      nws/        NWS API client — the only place that knows about
                   api.weather.gov URLs, headers, and HTTP status codes
      cache/      Local weather cache (SharedPreferences-backed)
      location/   Local saved-locations store
    repositories/ Combines the NWS client + cache behind a simple
                   getCached()/fetchAndCache() interface
  features/
    weather/      Dashboard screen + widgets, WeatherController (Riverpod)
    locations/    Saved locations list, add/edit form, LocationsController
    alerts/       Alerts tab and alert detail screen
    settings/     Appearance + about
  widgets/        Shared presentational widgets (cards, empty/error states)
  theme/          Light/dark ThemeData
```

The UI never touches raw NWS JSON — everything is converted to
`core/models` first, so NWS's response shapes can change without touching
any screen.

## Getting started

```
flutter pub get
flutter run            # pick a device, or -d chrome for web
```

## Testing

```
flutter test
```

Unit tests cover NWS response parsing (including missing/malformed fields),
unit conversions, condition/severity mapping, caching, and the repository's
fallback behavior — all against fixture JSON in `test/fixtures/`, not live
requests.

## Notes

- NWS requires a descriptive `User-Agent` on every request; update
  `lib/core/services/nws/nws_config.dart` if this app changes hands.
- Locations are added by coordinates (with optional free-text address/
  description labels) rather than a geocoded address search, to avoid
  pulling in a geocoding service. Device location is a natural next step —
  `LocationStore`/`LocationsController` are structured so it can be added
  as another source of `Location`s without changing the weather pipeline.
