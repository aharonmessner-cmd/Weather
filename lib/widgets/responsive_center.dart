import 'package:flutter/material.dart';

/// Caps content at a comfortable reading width and centers it on wide
/// surfaces, instead of letting a single-column list/form stretch
/// edge-to-edge on tablet/desktop. A no-op on phone-width screens, since
/// [maxWidth] is normally wider than a phone viewport already.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 680});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
