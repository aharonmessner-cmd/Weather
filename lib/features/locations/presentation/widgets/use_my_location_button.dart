import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../application/current_location_controller.dart';

/// A single "Use My Location" action that shows its own progress and — on
/// failure — a specific, actionable message inline (never a generic
/// "something went wrong"), for every state
/// [CurrentLocationController.useMyLocation] can end in.
///
/// Purely presentational: it triggers the controller and renders whatever
/// state it's in. Reacting to success (closing a sheet, showing a
/// confirmation) is the parent's job via `ref.listen`, since what "success"
/// should do differs between the first-launch screen and the add-location
/// sheet.
class UseMyLocationButton extends ConsumerWidget {
  const UseMyLocationButton({super.key, this.filled = true});

  /// Filled (primary, prominent) on first launch; outlined when it's one
  /// of several options in the add-location sheet.
  final bool filled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(currentLocationControllerProvider);
    final loading = state is CurrentLocationLoading;

    final button = filled
        ? FilledButton.icon(
            onPressed: loading ? null : () => ref.read(currentLocationControllerProvider.notifier).useMyLocation(),
            icon: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location_rounded),
            label: Text(loading ? 'Finding your location…' : 'Use My Location'),
          )
        : OutlinedButton.icon(
            onPressed: loading ? null : () => ref.read(currentLocationControllerProvider.notifier).useMyLocation(),
            icon: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location_rounded),
            label: Text(loading ? 'Finding your location…' : 'Use My Location'),
          );

    if (state is! CurrentLocationFailed) {
      return SizedBox(width: double.infinity, child: button);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        const SizedBox(height: 8),
        _FailureMessage(reason: state.reason),
      ],
    );
  }
}

class _FailureMessage extends ConsumerWidget {
  const _FailureMessage({required this.reason});

  final CurrentLocationFailureReason reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final (message, settingsAction) = switch (reason) {
      CurrentLocationFailureReason.permissionDenied => ('Location permission was denied.', null),
      CurrentLocationFailureReason.permissionDeniedForever => (
          'Location access is turned off for this app.',
          _SettingsAction.app,
        ),
      CurrentLocationFailureReason.servicesDisabled => (
          'Location services are turned off on this device.',
          _SettingsAction.location,
        ),
      CurrentLocationFailureReason.timeout => ("Couldn't get your location in time.", null),
      CurrentLocationFailureReason.unavailable => ('Your location is not available right now.', null),
      CurrentLocationFailureReason.nwsUnavailable => (
          "Weather isn't available for your current location.",
          null,
        ),
      CurrentLocationFailureReason.nwsTemporaryError => (
          "Couldn't confirm your location with the weather service. Check your connection.",
          null,
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline_rounded, size: 18, color: theme.colorScheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              if (settingsAction != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                    onPressed: () {
                      final service = ref.read(deviceLocationServiceProvider);
                      switch (settingsAction) {
                        case _SettingsAction.app:
                          service.openAppSettings();
                        case _SettingsAction.location:
                          service.openLocationSettings();
                      }
                    },
                    child: Text(settingsAction == _SettingsAction.app ? 'Open App Settings' : 'Open Location Settings'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _SettingsAction { app, location }
