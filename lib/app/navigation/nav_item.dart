import 'nav_glyphs.dart';

/// One destination's display data for the custom navigation surfaces —
/// deliberately platform/screen-size agnostic; [AppBottomNavBar] and
/// [AppNavRail] each decide how to lay this out.
class NavItemData {
  const NavItemData({
    required this.glyph,
    required this.label,
    this.badgeCount = 0,
  });

  final NavGlyphKind glyph;
  final String label;

  /// Shown as a small numeric badge on the glyph when > 0 (e.g. active
  /// alert count) — purely presentational, callers decide what it counts.
  final int badgeCount;
}
