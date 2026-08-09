import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/location.dart';
import '../../../widgets/empty_state.dart';
import '../application/locations_controller.dart';
import 'widgets/location_editor_sheet.dart';
import 'widgets/location_tile.dart';

class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationsControllerProvider);
    final selected = ref.watch(selectedLocationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Locations')),
      body: locations.isEmpty
          ? EmptyState(
              icon: Icons.location_off_outlined,
              title: 'No Locations Yet',
              message: 'Add a place — like Home, School, or Camp — to start seeing its weather.',
              action: FilledButton.icon(
                onPressed: () => _openEditor(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add a Location'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: locations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final location = locations[index];
                return LocationTile(
                  location: location,
                  isSelected: selected?.id == location.id,
                  onTap: () => ref.read(selectedLocationIdProvider.notifier).state = location.id,
                  onFavorite: () => ref.read(locationsControllerProvider.notifier).setFavorite(location.id),
                  onEdit: () => _openEditor(context, existing: location),
                  onDelete: () => _confirmDelete(context, ref, location),
                );
              },
            ),
      floatingActionButton: locations.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _openEditor(context),
              child: const Icon(Icons.add_rounded),
            ),
    );
  }

  Future<void> _openEditor(BuildContext context, {Location? existing}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => LocationEditorSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Location location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${location.name}?'),
        content: const Text('This removes the saved location and its cached weather.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(locationsControllerProvider.notifier).remove(location.id);
    }
  }
}
