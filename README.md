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

## MinuteCast (precipitation nowcast)

The "Rain starting in N min" / "Rain ending in N min" section above the
hourly forecast, and the UV Index metric in Weather Details, are both
powered by [Pirate Weather](https://pirateweather.net/), entirely separate
from NWS — they share the one free API key (pirate-weather.apiable.io)
passed at build/run time via `--dart-define`, never committed to the repo:

```
# Local development (hot reload):
flutter run -d chrome --dart-define=PIRATE_WEATHER_API_KEY=YOUR_KEY_HERE

# Local production-style build:
flutter build web --release --dart-define=PIRATE_WEATHER_API_KEY=YOUR_KEY_HERE
```

No `.env` file is needed or used anywhere in this project — the key only
ever exists as a `--dart-define` value (locally) or a GitHub Actions
secret (in CI, see below).

Without a key, `MinuteCastClient` checks `MinuteCastConfig.isConfigured`
and throws before ever making a network call — MinuteCast and UV Index
both simply don't render (no error shown, no "N/A"), and the rest of the
app (NWS current conditions, hourly, daily, alerts) is completely
unaffected. NWS remains the sole source for everything else the app
shows. The MinuteCast section is also hidden whenever no precipitation is
expected in the next hour — it's a "what's happening right now" feature,
not a general forecast card, so a dry hour means it simply isn't on
screen.

### Supplying the key in GitHub Actions (Pages deploy)

`.github/workflows/build-web.yml` builds and deploys the web app to
GitHub Pages on every push to `main`. Its "Build Flutter Web" step reads
the key from a **repository secret** — nothing is ever hardcoded in the
workflow file:

1. In the GitHub repo, go to **Settings → Secrets and variables →
   Actions → Repository secrets**.
2. Add a new secret named exactly **`PIRATE_WEATHER_API_KEY`** with your
   Pirate Weather key as the value.
3. That's it — the workflow already passes it through:
   `--dart-define=PIRATE_WEATHER_API_KEY="$PIRATE_WEATHER_API_KEY"`, with
   the secret scoped to just that build step via `env:` and referenced as
   a shell variable (not interpolated directly into the command string).
   GitHub also automatically redacts the secret's value from any workflow
   logs.

If the secret is never configured, the deployed site simply behaves the
same as an unconfigured local build: MinuteCast/UV Index don't appear,
everything else works normally.

**On the API key not being secret:** `--dart-define` values are compiled
into the app binary/bundle, not stored in a server-side secret manager.
That's fine for a debug build or a native app on your own device, but for
the **web build**, anything compiled into the JS bundle is visible to
anyone who opens browser dev tools — `--dart-define` does not make the key
confidential there. Since this is a private app for personal/friends use
against a free-tier key with no billing attached, that tradeoff is
accepted for now; don't rely on this pattern if the app ever needs a key
that must stay actually secret (that would need a small server-side proxy
instead). Never commit a real key to a source file, a checked-in JSON/env
file, or a log line — the key is passed only via the build-time
`--dart-define` flag.

## Zmanim (halachic times)

The Zmanim card at the very bottom of the Weather screen is powered by
[Hebcal's `/zmanim` REST API](https://www.hebcal.com/home/1663/zmanim-halachic-times-api),
entirely separate from both NWS and MinuteCast. No API key is needed —
Hebcal's zmanim endpoint is open — so there's nothing to configure to turn
it on.

- Shows only *today's* Zmanim for the currently selected location, and
  only the ones still ahead of the current time — rows disappear as the
  day passes rather than showing an always-full list.
- "Show Zmanim" in Settings turns the whole section on/off (default on);
  turning it off means no Hebcal requests are made at all.
- "Advanced Zmanim" in Settings lets you enable/disable individual rows,
  reorder them, rename them, change which Hebcal calculation/halachic
  opinion backs a row (e.g. Gra vs. Magen Avraham vs. Baal HaTanya, where
  Hebcal actually offers more than one), and add further Zmanim from
  Hebcal's full field set beyond the default 12.
- Content is Hebcal's, licensed
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) — see the
  attribution line in Settings → About.

Like MinuteCast, a Hebcal failure never affects the rest of the app: the
section just hides (falling back to a cached same-day snapshot when one
exists) and NWS weather keeps working normally.

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
