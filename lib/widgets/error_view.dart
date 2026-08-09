import 'package:flutter/material.dart';

import '../core/services/nws/nws_exceptions.dart';

/// Turns an [NwsException] (or any other error) into a friendly message
/// plus a retry button. Used whenever there's genuinely nothing to show —
/// once any data is cached, the UI should prefer showing that (marked
/// stale) over this.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _friendlyMessage(error),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _friendlyMessage(Object error) {
    if (error is NwsException) return error.message;
    return 'Something went wrong loading the weather.';
  }
}
