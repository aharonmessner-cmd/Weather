import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/models/minutecast/minute_cast.dart';
import 'package:weather/core/models/minutecast/minute_precipitation_forecast.dart';
import 'package:weather/core/repositories/minutecast_repository.dart';
import 'package:weather/core/services/minutecast/minutecast_exceptions.dart';
import 'package:weather/features/weather/presentation/widgets/minutecast_section.dart';
import 'package:weather/theme/glass_style.dart';
import 'package:weather/widgets/glass_card.dart';

const _dc = Location(id: 'dc', name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);

class _FakeMinuteCastRepository implements MinuteCastRepository {
  MinuteCast? cached;
  MinuteCast? nextFetch;
  Object? fetchError;

  @override
  Future<MinuteCast?> getCached(Location location) async => cached;

  @override
  Future<MinuteCast> fetchAndCache(Location location) async {
    if (fetchError != null) throw fetchError!;
    return nextFetch!;
  }
}

MinuteCast _snapshotStartingSoon() {
  final now = DateTime.now();
  return MinuteCast(
    generatedAt: now,
    location: _dc,
    minutes: [
      for (var i = 0; i < 20; i++)
        MinutePrecipitationForecast(
          time: now.add(Duration(minutes: i)),
          type: i >= 5 ? PrecipitationType.rain : PrecipitationType.none,
          probability: i >= 5 ? 0.8 : 0.0,
          intensityMmPerHour: i >= 5 ? 1.5 : 0.0,
        ),
    ],
    source: MinuteCastSource.pirateWeather,
  );
}

MinuteCast _snapshotCurrentlyRaining() {
  final now = DateTime.now();
  return MinuteCast(
    generatedAt: now,
    location: _dc,
    minutes: [
      for (var i = 0; i < 60; i++)
        MinutePrecipitationForecast(
          time: now.add(Duration(minutes: i)),
          type: i < 37 ? PrecipitationType.rain : PrecipitationType.none,
          probability: i < 37 ? 0.9 : 0.0,
          intensityMmPerHour: i < 37 ? 2.0 : 0.0,
        ),
    ],
    source: MinuteCastSource.pirateWeather,
  );
}

/// No minute anywhere in the data crosses the precipitation threshold --
/// this is what Pirate Weather's `minutely` block looks like both for "no
/// precipitation at all" and for "the next rain is beyond the ~60-minute
/// window this data covers" (e.g. rain at 1:00 PM when it's 10:38 AM):
/// either way, nothing in the *next hour's* data is wet, so the section
/// must hide.
MinuteCast _snapshotAllDry() {
  final now = DateTime.now();
  return MinuteCast(
    generatedAt: now,
    location: _dc,
    minutes: [
      for (var i = 0; i < 60; i++)
        MinutePrecipitationForecast(time: now.add(Duration(minutes: i)), type: PrecipitationType.none),
    ],
    source: MinuteCastSource.pirateWeather,
  );
}

Future<void> _pump(WidgetTester tester, _FakeMinuteCastRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [minuteCastRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: Scaffold(
          body: MinuteCastSection(
            location: _dc,
            contentColor: Colors.white,
            style: GlassStyle.onSkyDark,
            timeZone: 'America/New_York',
          ),
        ),
      ),
    ),
  );
  // MinuteCastSection starts a periodic refresh Timer in initState; unmount
  // it before the test ends so dispose() cancels that Timer, or flutter_test
  // fails the test with "A Timer is still pending" even though nothing here
  // is actually wrong.
  addTearDown(() => tester.pumpWidget(const SizedBox()));
}

void main() {
  testWidgets('with data available, renders the headline and does not throw', (tester) async {
    final repo = _FakeMinuteCastRepository()..nextFetch = _snapshotStartingSoon();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Rain starting in'), findsOneWidget);
  });

  testWidgets('while loading (no cache yet), renders nothing rather than a spinner or error', (tester) async {
    final repo = _FakeMinuteCastRepository()..nextFetch = _snapshotStartingSoon();
    await _pump(tester, repo);

    // Before the first frame's fetch resolves, the section must not show
    // any error UI -- it should simply render nothing yet.
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Error'), findsNothing);
  });

  testWidgets('when the repository throws and there is no cache, renders nothing (no error UI)', (tester) async {
    final repo = _FakeMinuteCastRepository()..fetchError = const MinuteCastServerException(500);
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Precipitation'), findsNothing);
    expect(find.textContaining('Error'), findsNothing);
  });

  testWidgets('when not configured, renders nothing (no error UI)', (tester) async {
    final repo = _FakeMinuteCastRepository()..fetchError = const MinuteCastNotConfiguredException();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Precipitation'), findsNothing);
  });

  testWidgets('while actively raining, renders and shows an "ending" headline', (tester) async {
    final repo = _FakeMinuteCastRepository()..nextFetch = _snapshotCurrentlyRaining();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Rain ending in'), findsOneWidget);
  });

  testWidgets('with no precipitation anywhere in the data, renders nothing at all', (tester) async {
    final repo = _FakeMinuteCastRepository()..nextFetch = _snapshotAllDry();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Precipitation'), findsNothing);
    expect(find.textContaining('Dry'), findsNothing);
    expect(find.byType(GlassCard), findsNothing);
  });

  testWidgets('rain more than 60 minutes away (outside the data window) renders nothing', (tester) async {
    // Equivalent to _snapshotAllDry from the section's point of view --
    // Pirate Weather simply wouldn't include a start time beyond its own
    // ~60-minute minutely window, so "far away" and "no rain at all" both
    // arrive here as an all-dry minute list.
    final repo = _FakeMinuteCastRepository()..nextFetch = _snapshotAllDry();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GlassCard), findsNothing);
  });

  testWidgets('with a stale cache, renders the "Updating" hint but still shows the headline', (tester) async {
    final stale = MinuteCast(
      generatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      location: _dc,
      minutes: _snapshotStartingSoon().minutes,
      source: MinuteCastSource.pirateWeather,
    );
    // The stale cache is old enough that build() schedules a quiet
    // background refresh -- make that refresh fail so the "stale" state
    // set from the cache stays on screen for this assertion instead of
    // flipping to "available" once the refresh lands.
    final repo = _FakeMinuteCastRepository()
      ..cached = stale
      ..fetchError = const MinuteCastNetworkException();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Updating'), findsOneWidget);
  });
}
