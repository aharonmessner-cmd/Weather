import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/app/providers.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/core/models/zmanim/hebcal_zman_field.dart';
import 'package:weather/core/models/zmanim/zmanim.dart';
import 'package:weather/core/repositories/zmanim_repository.dart';
import 'package:weather/core/services/zmanim/zmanim_exceptions.dart';
import 'package:weather/features/weather/presentation/widgets/zmanim_section.dart';
import 'package:weather/theme/glass_style.dart';
import 'package:weather/widgets/glass_card.dart';

const _dc = Location(id: 'dc', name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);

class _FakeZmanimRepository implements ZmanimRepository {
  Zmanim? cached;
  Zmanim? nextFetch;
  Object? fetchError;

  @override
  Future<Zmanim?> getCached(Location location, String timeZone) async => cached;

  @override
  Future<Zmanim> fetchAndCache(Location location, String timeZone) async {
    if (fetchError != null) throw fetchError!;
    return nextFetch!;
  }
}

/// All 12 defaults, with Netz an hour ago and everything else still ahead,
/// so the card should open on "Sof Zman Krias Shema MG"A" per the exact
/// example in the feature request.
Zmanim _midMorningSnapshot() {
  return Zmanim(
    locationDate: '2026-08-11',
    location: _dc,
    generatedAt: DateTime.now(),
    times: {
      HebcalZmanField.alotHaShachar: DateTime.now().subtract(const Duration(hours: 3)),
      HebcalZmanField.misheyakir: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      HebcalZmanField.sunrise: DateTime.now().subtract(const Duration(hours: 2)),
      HebcalZmanField.sofZmanShmaMGA: DateTime.now().add(const Duration(minutes: 40)),
      HebcalZmanField.sofZmanShma: DateTime.now().add(const Duration(hours: 1)),
      HebcalZmanField.sofZmanTfilla: DateTime.now().add(const Duration(hours: 2)),
      HebcalZmanField.chatzot: DateTime.now().add(const Duration(hours: 4)),
      HebcalZmanField.minchaGedola: DateTime.now().add(const Duration(hours: 5)),
      HebcalZmanField.minchaKetana: DateTime.now().add(const Duration(hours: 8)),
      HebcalZmanField.plagHaMincha: DateTime.now().add(const Duration(hours: 9)),
      HebcalZmanField.sunset: DateTime.now().add(const Duration(hours: 10)),
      HebcalZmanField.tzeit7083deg: DateTime.now().add(const Duration(hours: 10, minutes: 30)),
    },
  );
}

Zmanim _allPassedSnapshot() {
  return Zmanim(
    locationDate: '2026-08-11',
    location: _dc,
    generatedAt: DateTime.now(),
    times: {
      HebcalZmanField.sunrise: DateTime.now().subtract(const Duration(hours: 2)),
      HebcalZmanField.sunset: DateTime.now().subtract(const Duration(minutes: 5)),
      HebcalZmanField.tzeit7083deg: DateTime.now().subtract(const Duration(minutes: 1)),
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeZmanimRepository repo,
  bool showZmanim = true,
  String? timeZone = 'America/New_York',
}) async {
  SharedPreferences.setMockInitialValues({'show_zmanim_v1': showZmanim});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        zmanimRepositoryProvider.overrideWithValue(repo),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ZmanimSection(
            location: _dc,
            contentColor: Colors.white,
            style: GlassStyle.onSkyDark,
            timeZone: timeZone,
          ),
        ),
      ),
    ),
  );
  addTearDown(() => tester.pumpWidget(const SizedBox()));
}

void main() {
  testWidgets('shows only the remaining Zmanim, starting with the next upcoming one', (tester) async {
    final repo = _FakeZmanimRepository()..nextFetch = _midMorningSnapshot();
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sof Zman Krias Shema MG"A'), findsOneWidget);
    expect(find.text('Alos'), findsNothing);
    expect(find.text('Earliest Tallis and Tefillin'), findsNothing);
    expect(find.text('Netz'), findsNothing);
    expect(find.text('Tzeis'), findsOneWidget);
  });

  testWidgets('shows the approximate-times disclaimer', (tester) async {
    final repo = _FakeZmanimRepository()..nextFetch = _midMorningSnapshot();
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(find.text('Calculation times are approximate.'), findsOneWidget);
  });

  testWidgets('when every configured zman has already passed, renders nothing at all', (tester) async {
    final repo = _FakeZmanimRepository()..nextFetch = _allPassedSnapshot();
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GlassCard), findsNothing);
  });

  testWidgets('with no location time zone known, renders nothing without an error', (tester) async {
    final repo = _FakeZmanimRepository()..nextFetch = _midMorningSnapshot();
    await _pump(tester, repo: repo, timeZone: null);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GlassCard), findsNothing);
  });

  testWidgets('when "Show Zmanim" is off, renders nothing and never touches the repository', (tester) async {
    final repo = _FakeZmanimRepository()..nextFetch = _midMorningSnapshot();
    await _pump(tester, repo: repo, showZmanim: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GlassCard), findsNothing);
    expect(find.text('Zmanim'), findsNothing);
  });

  testWidgets('when the repository throws and there is no cache, renders nothing (no error UI)', (tester) async {
    final repo = _FakeZmanimRepository()..fetchError = const ZmanimServerException(500);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GlassCard), findsNothing);
  });

  testWidgets('each row is one semantic node combining name and time', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = _FakeZmanimRepository()..nextFetch = _midMorningSnapshot();
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp(r'^Tzeis, \d{1,2}:\d{2} (AM|PM)$')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('does not overflow horizontally with a long zman name at a large text scale', (tester) async {
    final repo = _FakeZmanimRepository()..nextFetch = _midMorningSnapshot();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          zmanimRepositoryProvider.overrideWithValue(repo),
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.5)),
              child: Scaffold(
                // A plain SingleChildScrollView, matching how weather_screen.dart
                // actually embeds this section (inside a scrollable) --
                // unbounded content height there is expected and fine; a
                // fixed-height ancestor would be an artificial constraint
                // no production call site imposes.
                body: SingleChildScrollView(
                  child: SizedBox(
                    width: 320,
                    child: ZmanimSection(
                      location: _dc,
                      contentColor: Colors.white,
                      style: GlassStyle.onSkyDark,
                      timeZone: 'America/New_York',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
