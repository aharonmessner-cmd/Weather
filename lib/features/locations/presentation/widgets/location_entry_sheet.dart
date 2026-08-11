import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/current_location_controller.dart';
import 'use_my_location_button.dart';

/// What the user picked in [LocationEntrySheet] — "Use My Location" acts
/// immediately within the sheet itself (see [UseMyLocationButton]), but
/// Search and Advanced both need a *second* sheet, which has to be opened
/// by the caller once this one has fully closed (see the doc on
/// [LocationEntrySheet] for why).
enum LocationEntryChoice { search, advanced }

/// The "add a location" entry point once the user already has at least one
/// saved location: search or device location up front, with manual
/// coordinate entry demoted to an "Advanced" option rather than the first
/// thing shown.
///
/// Pops with a [LocationEntryChoice] rather than opening the next sheet
/// itself: `showModalBottomSheet` from inside a `pop()`ing sheet's own
/// `onPressed`, in the same synchronous callback, could leave the next
/// sheet's layout momentarily inheriting the closing one's insets/route
/// transition — popping a typed result and letting the (still-mounted)
/// caller open the next sheet is the same pattern this screen already uses
/// for the delete-confirmation dialog.
class LocationEntrySheet extends ConsumerWidget {
  const LocationEntrySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "Use My Location" succeeding while this sheet is open means a
    // location now exists and is selected — close the sheet so the caller
    // sees it land in the (no-longer-empty) list underneath.
    ref.listen(currentLocationControllerProvider, (previous, next) {
      if (next is CurrentLocationSucceeded) Navigator.of(context).pop();
    });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Location', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.search_rounded),
              label: const Text('Search for a Location'),
              onPressed: () => Navigator.of(context).pop(LocationEntryChoice.search),
            ),
            const SizedBox(height: 12),
            const UseMyLocationButton(filled: false),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Advanced: Enter Coordinates'),
              onPressed: () => Navigator.of(context).pop(LocationEntryChoice.advanced),
            ),
          ],
        ),
      ),
    );
  }
}
