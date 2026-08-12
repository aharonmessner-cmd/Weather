import 'package:flutter/material.dart';

/// The single selected-state treatment used by both the bottom bar and
/// the side rail: a soft, low-radius glow behind the icon that fades in
/// on selection, plus the glyph itself brightening (handled by
/// [NavGlyph]'s `selected` flag). Chosen deliberately as the *one*
/// mechanism rather than combining several — no pill, no underline, no
/// background fill; just illumination, animated so switching tabs reads
/// as the glow drifting to the new destination.
class NavGlow extends StatelessWidget {
  const NavGlow({
    super.key,
    required this.selected,
    required this.color,
    required this.child,
    this.size = 44,
  });

  final bool selected;
  final Color color;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: selected ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
