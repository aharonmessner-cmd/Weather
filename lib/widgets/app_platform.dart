import 'package:flutter/foundation.dart';

/// Which navigation *idiom* to use, independent of window size.
///
/// [ScreenSize] (see `responsive.dart`) answers "how much room is there";
/// this answers "what does this OS expect a native app chrome to look
/// like" — the two are deliberately orthogonal. A wide iPad and a narrow
/// Android phone both need their own platform idiom regardless of which
/// [ScreenSize] bucket they fall into, and a desktop browser window should
/// never be mistaken for a phone just because it happens to be narrow.
enum AppPlatform {
  ios,
  android,

  /// Web (any browser, any OS) and native desktop (macOS/Windows/Linux).
  /// These share one idiom: a flatter, more restrained surface than
  /// either mobile OS's own chrome, since there's no single native "OS
  /// nav bar" look to draw from.
  webOrDesktop,
}

/// Resolves the current [AppPlatform] using Flutter's real platform
/// signals (`kIsWeb`, `defaultTargetPlatform`) rather than window width —
/// a desktop browser stays [AppPlatform.webOrDesktop] no matter how
/// narrow its window gets, and a phone stays [AppPlatform.ios] or
/// [AppPlatform.android] no matter how it's rotated or split-screened.
AppPlatform get currentAppPlatform {
  if (kIsWeb) return AppPlatform.webOrDesktop;
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => AppPlatform.ios,
    TargetPlatform.android => AppPlatform.android,
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux ||
    TargetPlatform.fuchsia =>
      AppPlatform.webOrDesktop,
  };
}
