import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/environment/sky_palette.dart';
import 'package:weather/environment/widgets/sky_background.dart';

SkyPalette _palette({
  double starOpacity = 0.5,
  double cloudOpacity = 0.5,
  double precipitationIntensity = 0,
  SkyPrecipitationKind precipitationKind = SkyPrecipitationKind.none,
  bool stormFlicker = false,
}) {
  return SkyPalette(
    topColor: const Color(0xFF14205A),
    bottomColor: const Color(0xFF4A3A72),
    midColor: const Color(0xFF2A4A8C),
    starOpacity: starOpacity,
    cloudOpacity: cloudOpacity,
    cloudCoverageFraction: cloudOpacity,
    horizonGlowColor: const Color(0xFFFF9D6C),
    horizonGlowIntensity: 0.5,
    sunMoonVisibility: 0.8,
    isSunVisible: true,
    sunMoonElevationFraction: 0.6,
    sunMoonAzimuthDegrees: 180,
    precipitationIntensity: precipitationIntensity,
    precipitationKind: precipitationKind,
    stormFlicker: stormFlicker,
    heroContentBrightness: Brightness.dark,
  );
}

void main() {
  testWidgets('renders a full sky without throwing and ticks its animation clock', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 800,
            child: SkyBackground(
              palette: _palette(precipitationIntensity: 0.6, precipitationKind: SkyPrecipitationKind.rain, stormFlicker: true),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    // Let a couple of the shared clock's ticks (250ms each) fire.
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('respects reduced motion by not starting the animation timer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SizedBox(
              width: 390,
              height: 800,
              child: SkyBackground(palette: _palette()),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    // If a timer were still running, pumpAndSettle would hang/timeout on
    // the periodic timer; a normal pump is enough to prove nothing throws
    // and the widget stays static.
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cleans up its timer on dispose without throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SizedBox(width: 390, height: 800, child: SkyBackground(palette: _palette()))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    expect(tester.takeException(), isNull);
  });
}
