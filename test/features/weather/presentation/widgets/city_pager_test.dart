import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/core/models/location.dart';
import 'package:weather/features/weather/presentation/widgets/city_pager.dart';

const _dc = Location(id: 'dc', name: 'Washington, DC', latitude: 38.8894, longitude: -77.0352);
const _camp = Location(id: 'camp', name: 'Camp Runamuck', latitude: 44.2, longitude: -71.5);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<Location> locations,
    String? selectedId,
    required ValueChanged<String> onSelect,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CityPager(
            locations: locations,
            selectedId: selectedId,
            onSelect: onSelect,
            contentColor: Colors.white,
          ),
        ),
      ),
    );
  }

  testWidgets('renders nothing with a single saved location', (tester) async {
    await pump(tester, locations: const [_dc], selectedId: 'dc', onSelect: (_) {});
    expect(find.text('Washington, DC'), findsNothing);
  });

  testWidgets('renders nothing with zero saved locations', (tester) async {
    await pump(tester, locations: const [], selectedId: null, onSelect: (_) {});
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a chip per location when there are two or more', (tester) async {
    await pump(tester, locations: const [_dc, _camp], selectedId: 'dc', onSelect: (_) {});
    expect(find.text('Washington, DC'), findsOneWidget);
    expect(find.text('Camp Runamuck'), findsOneWidget);
  });

  testWidgets('tapping a chip calls onSelect with that location\'s id', (tester) async {
    String? selected;
    await pump(tester, locations: const [_dc, _camp], selectedId: 'dc', onSelect: (id) => selected = id);

    await tester.tap(find.text('Camp Runamuck'));
    await tester.pump();

    expect(selected, 'camp');
  });

  testWidgets('exposes selected state via semantics for the current location, not others', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, locations: const [_dc, _camp], selectedId: 'dc', onSelect: (_) {});

    final dcNode = tester.getSemantics(find.text('Washington, DC'));
    final campNode = tester.getSemantics(find.text('Camp Runamuck'));

    expect(dcNode.hasFlag(SemanticsFlag.isSelected), isTrue);
    expect(campNode.hasFlag(SemanticsFlag.isSelected), isFalse);

    handle.dispose();
  });
}
