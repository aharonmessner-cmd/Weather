import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'nav_glow.dart';
import 'nav_glyphs.dart';
import 'nav_item.dart';
import 'nav_style.dart';

/// The custom tablet/desktop side rail — replaces Material's
/// [NavigationRail] outright. Compact (tablet width) shows icons only;
/// extended (desktop width) also shows labels, matching the existing
/// compact/extended split the app already made at these breakpoints, just
/// rendered with the app's own glyphs/glow instead of a recolored
/// [NavigationRail].
class AppNavRail extends StatelessWidget {
  const AppNavRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.style,
    required this.palette,
    required this.accentColor,
    required this.extended,
  });

  final List<NavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final NavPlatformStyle style;
  final ChromePalette palette;
  final Color accentColor;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final width = extended ? 220.0 : 84.0;
    final topInset = MediaQuery.paddingOf(context).top;

    final content = Container(
      width: width,
      decoration: BoxDecoration(
        color: style.fill,
        border: Border(right: BorderSide(color: style.border, width: style.borderWidth)),
        boxShadow: style.shadow,
      ),
      padding: EdgeInsets.only(top: topInset + 20, bottom: 20),
      child: Column(
        crossAxisAlignment: extended ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _RailItem(
                item: items[i],
                selected: i == selectedIndex,
                accentColor: accentColor,
                mutedColor: palette.textSecondary,
                extended: extended,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );

    if (style.blurSigma <= 0) return content;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: style.blurSigma, sigmaY: style.blurSigma),
      child: content,
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.item,
    required this.selected,
    required this.accentColor,
    required this.mutedColor,
    required this.extended,
    required this.onTap,
  });

  final NavItemData item;
  final bool selected;
  final Color accentColor;
  final Color mutedColor;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? accentColor : mutedColor;
    final glyphAndBadge = Stack(
      alignment: Alignment.center,
      children: [
        NavGlyph(kind: item.glyph, color: color, selected: selected),
        if (item.badgeCount > 0)
          Positioned(
            top: -2,
            right: extended ? -2 : -8,
            child: _RailBadge(count: item.badgeCount),
          ),
      ],
    );

    return Semantics(
      button: true,
      selected: selected,
      label: extended ? null : item.label,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: accentColor.withValues(alpha: 0.06),
          focusColor: accentColor.withValues(alpha: 0.12),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: extended ? 12 : 0),
            child: extended
                ? Row(
                    children: [
                      NavGlow(selected: selected, color: accentColor, size: 40, child: glyphAndBadge),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: NavGlow(selected: selected, color: accentColor, size: 44, child: glyphAndBadge),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RailBadge extends StatelessWidget {
  const _RailBadge({required this.count});

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
