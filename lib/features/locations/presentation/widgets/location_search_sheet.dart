import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/geocode_result.dart';
import '../../application/location_search_controller.dart';
import '../../application/locations_controller.dart';

/// Search-by-name entry point: a query field plus whatever
/// [LocationSearchController] currently holds — idle, loading, results, a
/// clear "no results" state, or a retryable error. Search only runs when
/// the user submits (button tap or keyboard "search" action), never per
/// keystroke.
class LocationSearchSheet extends ConsumerStatefulWidget {
  const LocationSearchSheet({super.key});

  @override
  ConsumerState<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends ConsumerState<LocationSearchSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    // A fresh sheet always starts from a clean slate rather than showing
    // whatever the last search session left behind.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(locationSearchControllerProvider);
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _controller.text;
    setState(() => _lastQuery = query.trim());
    ref.read(locationSearchControllerProvider.notifier).search(query);
  }

  Future<void> _select(GeocodeResult result) async {
    final messenger = ScaffoldMessenger.of(context);
    final saveResult = await ref.read(locationsControllerProvider.notifier).add(
          name: result.name,
          latitude: result.latitude,
          longitude: result.longitude,
          address: result.subtitle,
        );
    ref.read(selectedLocationIdProvider.notifier).state = saveResult.location.id;

    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saveResult.wasDuplicate
              ? 'You already have ${saveResult.location.name} saved — selected it.'
              : 'Added ${saveResult.location.name}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationSearchControllerProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search for a Location', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'City, "City, ST", or ZIP code',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded),
                    tooltip: 'Search',
                    onPressed: _submit,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 80, maxHeight: 360),
                child: _SearchBody(state: state, query: _lastQuery, onRetry: _submit, onSelect: _select),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({required this.state, required this.query, required this.onRetry, required this.onSelect});

  final LocationSearchState state;
  final String query;
  final VoidCallback onRetry;
  final ValueChanged<GeocodeResult> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (state) {
      LocationSearchIdle() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Search for a city, "City, ST", or ZIP code.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      LocationSearchLoading() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      LocationSearchEmpty() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No locations found for "$query".',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      LocationSearchError(:final message) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      LocationSearchResults(:final results) => ListView.separated(
          shrinkWrap: true,
          itemCount: results.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(result.name),
              subtitle: Text(result.subtitle),
              onTap: () => onSelect(result),
            );
          },
        ),
    };
  }
}
