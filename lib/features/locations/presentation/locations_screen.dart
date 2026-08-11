import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/location.dart';
import '../../../widgets/responsive_center.dart';
import '../application/current_location_controller.dart';
import '../application/locations_controller.dart';
import 'widgets/location_editor_sheet.dart';
import 'widgets/location_entry_sheet.dart';
import 'widgets/location_onboarding.dart';
import 'widgets/location_search_sheet.dart';
import 'widgets/location_tile.dart';

class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationsControllerProvider);
    final selected = ref.watch(selectedLocationProvider);

    // Single place to confirm a "Use My Location" success, regardless of
    // whether it was triggered from the empty-state onboarding view below
    // or from the add-location sheet (which handles closing itself).
    ref.listen(currentLocationControllerProvider, (previous, next) {
      if (next is! CurrentLocationSucceeded) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next.wasDuplicate
                ? 'You already have ${next.location.name} saved — selected it.'
                : 'Added ${next.location.name}.',
          ),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Locations')),
      body: locations.isEmpty
          ? const LocationOnboarding()
          : ResponsiveCenter(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: locations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final location = locations[index];
                  return LocationTile(
                    location: location,
                    isSelected: selected?.id == location.id,
                    onTap: () =>
                        ref.read(selectedLocationIdProvider.notifier).state =
                            location.id,
                    onFavorite: () => ref
                        .read(locationsControllerProvider.notifier)
                        .setFavorite(location.id),
                    onEdit: () => _openEditor(context, existing: location),
                    onDelete: () => _confirmDelete(context, ref, location),
                  );
                },
              ),
            ),
      floatingActionButton: locations.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _openEntrySheet(context),
              child: const Icon(Icons.add_rounded),
            ),
    );
  }

  Future<void> _openEntrySheet(BuildContext context) async {
    final choice = await showModalBottomSheet<LocationEntryChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (_) => const LocationEntrySheet(),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case LocationEntryChoice.search:
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          constraints: const BoxConstraints(maxWidth: 480),
          builder: (_) => const LocationSearchSheet(),
        );
      case LocationEntryChoice.advanced:
        await _openEditor(context);
    }
  }

  Future<void> _openEditor(BuildContext context, {Location? existing}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (_) => LocationEditorSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Location location,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${location.name}?'),
        content: const Text(
          'This removes the saved location and its cached weather.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(locationsControllerProvider.notifier).remove(location.id);
    }
  }
}
