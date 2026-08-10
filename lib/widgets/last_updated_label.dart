import 'package:flutter/material.dart';

/// A small "Updated 5m ago" caption, styled as a warning when the data is
/// stale so the user always knows whether they're looking at something
/// fresh or something the app couldn't refresh.
class LastUpdatedLabel extends StatelessWidget {
  const LastUpdatedLabel({super.key, required this.fetchedAt, this.isStale = false, this.color});

  final DateTime fetchedAt;
  final bool isStale;

  /// Overrides the default theme-based coloring — used on the Weather
  /// screen, where this sits on the dynamic sky rather than a normal
  /// surface and needs to match the sky's resolved content color instead.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? (isStale ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isStale) ...[
          Icon(Icons.cloud_off_rounded, size: 13, color: resolvedColor),
          const SizedBox(width: 4),
        ],
        Text(
          isStale ? 'Offline · updated ${_relativeTime(fetchedAt)}' : 'Updated ${_relativeTime(fetchedAt)}',
          style: theme.textTheme.labelSmall?.copyWith(color: resolvedColor),
        ),
      ],
    );
  }

  static String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
