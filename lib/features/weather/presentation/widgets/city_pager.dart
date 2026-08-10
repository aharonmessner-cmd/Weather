import 'package:flutter/material.dart';

import '../../../../core/models/location.dart';
import '../../../../theme/app_typography.dart';

/// A row of quick-switch chips for saved locations, sitting directly under
/// the location name on the Weather screen's hero. This is the "Figma
/// city pager" idea, scoped down to a tap-to-switch chip row rather than a
/// full-screen swipeable pager — switching the whole dashboard (sky, hero,
/// every card) on a horizontal drag would fight the same gesture
/// [RefreshIndicator] already owns on this screen, and a chip row gets the
/// same "quick switch between saved places" outcome without that conflict.
///
/// The full [LocationsScreen] remains the place for add/edit/delete/
/// reorder — this is purely a shortcut, and renders nothing when there's
/// only one saved location to switch between.
class CityPager extends StatelessWidget {
  const CityPager({
    super.key,
    required this.locations,
    required this.selectedId,
    required this.onSelect,
    required this.contentColor,
  });

  final List<Location> locations;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final Color contentColor;

  @override
  Widget build(BuildContext context) {
    if (locations.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: locations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final location = locations[index];
          final selected = location.id == selectedId;
          return _CityChip(
            label: location.name,
            selected: selected,
            contentColor: contentColor,
            onTap: () => onSelect(location.id),
          );
        },
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({
    required this.label,
    required this.selected,
    required this.contentColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color contentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: contentColor.withValues(alpha: selected ? 0.18 : 0.0),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: contentColor.withValues(alpha: selected ? 0.28 : 0.14)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: contentColor.withValues(alpha: selected ? 1.0 : 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
