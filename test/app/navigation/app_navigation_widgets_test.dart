import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/app/navigation/app_bottom_nav_bar.dart';
import 'package:weather/app/navigation/app_nav_rail.dart';
import 'package:weather/app/navigation/nav_glyphs.dart';
import 'package:weather/app/navigation/nav_item.dart';
import 'package:weather/app/navigation/nav_style.dart';
import 'package:weather/theme/app_colors.dart';
import 'package:weather/widgets/app_platform.dart';

const _items = [
  NavItemData(glyph: NavGlyphKind.weather, label: 'Weather'),
  NavItemData(glyph: NavGlyphKind.locations, label: 'Locations'),
  NavItemData(glyph: NavGlyphKind.alerts, label: 'Alerts', badgeCount: 3),
  NavItemData(glyph: NavGlyphKind.settings, label: 'Settings'),
];

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('currentAppPlatform', () {
    setUp(() => debugDefaultTargetPlatformOverride = null);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('maps iOS to AppPlatform.ios', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(currentAppPlatform, AppPlatform.ios);
    });

    test('maps Android to AppPlatform.android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(currentAppPlatform, AppPlatform.android);
    });

    test('maps desktop platforms to AppPlatform.webOrDesktop', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(currentAppPlatform, AppPlatform.webOrDesktop);
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(currentAppPlatform, AppPlatform.webOrDesktop);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(currentAppPlatform, AppPlatform.webOrDesktop);
    });
  });

  group('NavPlatformStyle', () {
    test('iOS floats with a real blur; Android is edge-attached with a lighter blur', () {
      final ios = NavPlatformStyle.of(AppPlatform.ios, AppColors.dark, Brightness.dark);
      final android = NavPlatformStyle.of(AppPlatform.android, AppColors.dark, Brightness.dark);

      expect(ios.floating, isTrue);
      expect(android.floating, isFalse);
      expect(ios.blurSigma, greaterThan(0));
      expect(android.blurSigma, greaterThan(0));
      // Android must not reuse the iOS recipe verbatim.
      expect(android.blurSigma, isNot(ios.blurSigma));
    });

    test('web/desktop has no blur (flatter, more static surface)', () {
      final web = NavPlatformStyle.of(AppPlatform.webOrDesktop, AppColors.light, Brightness.light);
      expect(web.blurSigma, 0);
      expect(web.floating, isFalse);
    });
  });

  group('NavGlyph', () {
    for (final kind in NavGlyphKind.values) {
      testWidgets('renders $kind selected and unselected without throwing', (tester) async {
        await tester.pumpWidget(_wrap(NavGlyph(kind: kind, color: Colors.white, selected: true)));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(_wrap(NavGlyph(kind: kind, color: Colors.white)));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('AppBottomNavBar', () {
    Widget buildBar({int selectedIndex = 0, required ValueChanged<int> onSelected, NavPlatformStyle? style}) {
      return _wrap(
        AppBottomNavBar(
          items: _items,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
          style: style ?? NavPlatformStyle.of(AppPlatform.android, AppColors.dark, Brightness.dark),
          palette: AppColors.dark,
          accentColor: AppColors.accentCool,
        ),
      );
    }

    testWidgets('shows a label for every destination and reports taps by index', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(buildBar(onSelected: taps.add));

      for (final item in _items) {
        expect(find.text(item.label), findsOneWidget);
      }

      await tester.tap(find.text('Locations'));
      expect(taps, [1]);

      await tester.tap(find.text('Settings'));
      expect(taps, [1, 3]);
    });

    testWidgets('shows the badge count on a destination that has one', (tester) async {
      await tester.pumpWidget(buildBar(onSelected: (_) {}));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('marks the selected destination via Semantics(selected: true)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildBar(selectedIndex: 2, onSelected: (_) {}));

      final alertsSemantics = tester.getSemantics(find.text('Alerts'));
      expect(alertsSemantics.hasFlag(SemanticsFlag.isSelected), isTrue);

      final weatherSemantics = tester.getSemantics(find.text('Weather'));
      expect(weatherSemantics.hasFlag(SemanticsFlag.isSelected), isFalse);

      handle.dispose();
    });

    testWidgets('renders without overflow across the iOS/Android/web platform styles', (tester) async {
      for (final platform in AppPlatform.values) {
        final style = NavPlatformStyle.of(platform, AppColors.dark, Brightness.dark);
        await tester.pumpWidget(buildBar(onSelected: (_) {}, style: style));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'platform=$platform');
      }
    });
  });

  group('AppNavRail', () {
    Widget buildRail({required bool extended, required ValueChanged<int> onSelected}) {
      return _wrap(
        AppNavRail(
          items: _items,
          selectedIndex: 0,
          onSelected: onSelected,
          style: NavPlatformStyle.of(AppPlatform.webOrDesktop, AppColors.light, Brightness.light),
          palette: AppColors.light,
          accentColor: AppColors.accentCool,
          extended: extended,
        ),
      );
    }

    testWidgets('extended rail shows labels for every destination', (tester) async {
      await tester.pumpWidget(buildRail(extended: true, onSelected: (_) {}));
      for (final item in _items) {
        expect(find.text(item.label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact rail has no visible label text, but keeps it as a Semantics label', (tester) async {
      await tester.pumpWidget(buildRail(extended: false, onSelected: (_) {}));
      for (final item in _items) {
        expect(find.text(item.label), findsNothing);
      }
      expect(find.bySemanticsLabel('Weather'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a compact rail item (via its semantics) reports the right index', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(buildRail(extended: false, onSelected: taps.add));

      await tester.tap(find.bySemanticsLabel('Settings'));
      expect(taps, [3]);
    });
  });
}
