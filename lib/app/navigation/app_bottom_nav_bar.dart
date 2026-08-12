import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'nav_glow.dart';
import 'nav_glyphs.dart';
import 'nav_item.dart';
import 'nav_style.dart';

/// The custom mobile bottom navigation — replaces Material's
/// [NavigationBar] outright rather than restyling it. Every destination
/// keeps a small always-visible label (for tap targets and screen
/// readers alike); the only thing that changes on selection is the
/// glyph/label brightening to the accent color and the soft glow behind
/// the icon (see [NavGlow]) — no pill, no background fill.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.style,
    required this.palette,
    required this.accentColor,
  });

  final List<NavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final NavPlatformStyle style;
  final ChromePalette palette;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final radius = BorderRadius.circular(style.floating ? 28 : 20);

    final bar = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: style.blurSigma > 0
            ? ImageFilter.blur(sigmaX: style.blurSigma, sigmaY: style.blurSigma)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: style.fill,
            borderRadius: radius,
            border: Border.all(color: style.border, width: style.borderWidth),
            boxShadow: style.shadow,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _BottomNavItem(
                    item: items[i],
                    selected: i == selectedIndex,
                    accentColor: accentColor,
                    mutedColor: palette.textSecondary,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!style.floating) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: bar,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? bottomInset - 4 : 12),
      child: bar,
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.item,
    required this.selected,
    required this.accentColor,
    required this.mutedColor,
    required this.onTap,
  });

  final NavItemData item;
  final bool selected;
  final Color accentColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? accentColor : mutedColor;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: accentColor.withValues(alpha: 0.06),
          focusColor: accentColor.withValues(alpha: 0.12),
          child: SizedBox(
            height: 64,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  NavGlow(
                    selected: selected,
                    color: accentColor,
                    size: 34,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        NavGlyph(kind: item.glyph, color: color, selected: selected, size: 22),
                        if (item.badgeCount > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _Badge(count: item.badgeCount),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? accentColor : mutedColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AlertColors.severe,
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(minWidth: 14),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppTypography.fontBody,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
