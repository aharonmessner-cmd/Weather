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
```

**Web (Chrome):**
```
flutter run -d chrome
```

**Android** (emulator running, or a device connected with USB debugging on):
```
flutter devices        # confirm the device/emulator shows up
flutter run -d <device-id>
```

**iOS** (macOS + Xcode only — cannot be built or run on Linux/Windows):
```
open ios/Runner.xcworkspace   # first run: select a signing team in Xcode
flutter devices
flutter run -d <device-id>
```

## Testing

```
flutter test
```

Unit tests cover NWS response parsing (including missing/malformed fields),
unit conversions, condition/severity mapping, caching, and the repository's
fallback behavior — all against fixture JSON in `test/fixtures/`, not live
requests. No test constructs a real `http.Client`/`NwsApiClient` — every
test that touches the NWS client passes an explicit `MockClient`, so
`flutter test` never makes a network call.

## Debug logging (NWS requests)

`NwsApiClient` can log every request it makes — HTTP method, full endpoint
URL, and the resulting status code (or error type, e.g. `timeout`) — for
diagnosing live-API behavior. It's off by default and never logs headers or
response bodies, so the User-Agent's contact email and any response content
(e.g. alert text) never end up in logs.

Enable it for a single run:
```
flutter run -d chrome --dart-define=NWS_DEBUG_LOGGING=true
```

Example output (visible in the `flutter run` console / DevTools logging view):
```
[NWS] GET https://api.weather.gov/points/38.8894,-77.0352 -> 200 (312ms)
[NWS] GET https://api.weather.gov/gridpoints/LWX/97,71/forecast -> 200 (187ms)
[NWS] GET https://api.weather.gov/gridpoints/LWX/97,71/forecast/hourly -> 200 (201ms)
[NWS] GET https://api.weather.gov/gridpoints/LWX/97,71/stations -> 200 (150ms)
[NWS] GET https://api.weather.gov/stations/KDCA/observations/latest -> 503 (89ms)
[NWS] GET https://api.weather.gov/stations/KADW/observations/latest -> 200 (142ms)
[NWS] GET https://api.weather.gov/alerts/active?point=38.8894%2C-77.0352 -> 200 (95ms)
```
The `bool.fromEnvironment` define is also checked against `kReleaseMode`, so
it cannot stay on in a release build even if left in a build script by
mistake.

## Manual QA checklist (live NWS)

Automated tests only ever exercise fixture data. Before trusting a change,
run through this against the real API at least once:

- **Current conditions** — temperature/feels-like/condition match what the
  station is actually reporting; today's H/L look sane.
- **Hourly forecast** — scrolls smoothly, times are in the right order and
  timezone, precipitation % only shows when non-zero.
- **Daily forecast** — one row per calendar day, high ≥ low, the range bars
  reflect relative highs/lows across the visible days.
- **Alerts** — add a location currently under an active NWS alert (check
  https://alerts.weather.gov first) and confirm it shows up, is colored by
  severity, and the detail screen renders full text.
- **Saved locations** — add/edit/delete, set favorite, switch between two+
  locations and confirm the Weather tab follows the selection.
- **Cached/offline behavior** — load once with network on, then turn off
  networking (airplane mode / dev tools offline) and relaunch: cached data
  should appear immediately, marked stale after enough time has passed.
  Pull-to-refresh (or the refresh button) while offline should fail
  gracefully and leave the stale data on screen.
- **Partial endpoint failures** — worth deliberately triggering if you can
  (e.g. block `stations.weather.gov` in dev tools' network conditions, or
  wait for a station that's genuinely offline): current conditions should
  still show using the forecast as a fallback, and the Alerts tab shouldn't
  break just because the forecast succeeded.

## Notes

- NWS requires a descriptive `User-Agent` on every request; update
  `lib/core/services/nws/nws_config.dart` if this app changes hands.
- Locations are added by coordinates (with optional free-text address/
  description labels) rather than a geocoded address search, to avoid
  pulling in a geocoding service. Device location is a natural next step —
  `LocationStore`/`LocationsController` are structured so it can be added
  as another source of `Location`s without changing the weather pipeline.
