import 'package:flutter/material.dart';

import '../../../../core/models/location.dart';

/// One row in the saved-locations list: name, optional address/description,
/// a favorite toggle, and an overflow menu for edit/delete. Tapping the
/// tile itself selects the location for the Weather tab.
class LocationTile extends StatelessWidget {
  const LocationTile({
    super.key,
    required this.location,
    required this.isSelected,
    required this.onTap,
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
  });

  final Location location;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (location.description != null && location.description!.isNotEmpty) location.description!,
      if (location.address != null && location.address!.isNotEmpty) location.address!,
    ].join(' · ');

    return Card(
      color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 20, right: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onTap: onTap,
        title: Text(location.name, style: theme.textTheme.titleMedium),
        subtitle: subtitle.isEmpty
            ? Text(
                '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                style: theme.textTheme.bodySmall,
              )
            : Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          tooltip: location.isFavorite ? 'Favorite location' : 'Set as favorite',
          icon: Icon(
            location.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            color: location.isFavorite ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: onFavorite,
        ),
        trailing: PopupMenuButton<void>(
          icon: const Icon(Icons.more_vert_rounded),
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: onEdit,
              child: const ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'), contentPadding: EdgeInsets.zero),
            ),
            PopupMenuItem(
              onTap: onDelete,
              child: const ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete'), contentPadding: EdgeInsets.zero),
            ),
          ],
        ),
      ),
    );
  }
}
