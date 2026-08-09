import 'package:flutter/widgets.dart';

/// Coarse screen-size buckets the app lays out differently for, per the
/// "don't just stretch the phone UI" requirement.
enum ScreenSize { mobile, tablet, desktop }

const double kTabletBreakpoint = 600;
const double kDesktopBreakpoint = 1024;

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= kDesktopBreakpoint) return ScreenSize.desktop;
  if (width >= kTabletBreakpoint) return ScreenSize.tablet;
  return ScreenSize.mobile;
}
