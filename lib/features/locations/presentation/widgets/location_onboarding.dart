import 'package:flutter/material.dart';

import 'location_editor_sheet.dart';
import 'location_search_sheet.dart';
import 'use_my_location_button.dart';

/// What a new user sees before saving their first location: two clear,
/// prominent choices rather than a bare coordinate-entry form. Manual entry
/// is still reachable (a small link below), just not the first thing shown.
class LocationOnboarding extends StatelessWidget {
  const LocationOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wb_sunny_outlined, size: 56, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Where should we get your weather?',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const UseMyLocationButton(),
              const SizedBox(height: 12),
              Text('or', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Search for a Location'),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    constraints: const BoxConstraints(maxWidth: 480),
                    builder: (_) => const LocationSearchSheet(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  constraints: const BoxConstraints(maxWidth: 480),
                  builder: (_) => const LocationEditorSheet(),
                ),
                child: const Text('Enter coordinates manually'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
