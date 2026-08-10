/// Spacing and radius tokens, plus a per-breakpoint density multiplier.
///
/// Values are tighter than the previous Material-default theme — the
/// reference direction reads denser and more considered than a standard
/// dashboard-of-cards layout.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 40;

  static const double cardGap = 12;
  static const double gridGap = 10;

  static const double radiusCard = 22;
  static const double radiusChip = 14;
  static const double radiusPill = 20;
}
