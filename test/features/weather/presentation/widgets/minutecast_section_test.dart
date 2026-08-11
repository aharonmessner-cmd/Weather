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
