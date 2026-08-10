import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/glass_style.dart';

/// Renders a [GlassStyle] recipe as an actual widget: backdrop blur, subtle
/// translucent fill, hairline border, rounded corners. The shared surface
/// every Stage 3+ card sits on, so the "glass subordinate to the sky"
/// balance (fill opacity, blur amount) only has to be tuned in one place.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.style,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final GlassStyle style;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(style.radius);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: radius,
        border: Border.all(color: style.border, width: style.borderWidth),
      ),
      child: child,
    );

    if (style.blurSigma <= 0) {
      return ClipRRect(borderRadius: radius, child: content);
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: style.blurSigma, sigmaY: style.blurSigma),
        child: content,
      ),
    );
  }
}
