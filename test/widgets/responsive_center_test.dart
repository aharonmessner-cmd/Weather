import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/widgets/responsive_center.dart';

void main() {
  Future<void> pump(WidgetTester tester, double width) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: const ResponsiveCenter(
              maxWidth: 680,
              child: SizedBox(key: Key('content'), width: 2000, height: 40),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('caps content width on a wide surface', (tester) async {
    await pump(tester, 1400);

    final size = tester.getSize(find.byKey(const Key('content')));
    expect(size.width, 680);
  });

  testWidgets('does not throw on a narrow phone-width surface', (tester) async {
    await pump(tester, 360);
    expect(tester.takeException(), isNull);
  });
}
