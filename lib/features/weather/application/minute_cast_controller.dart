import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/models/location.dart';
import '../../../core/models/minutecast/minute_cast.dart';
import '../../../core/repositories/minutecast_repository.dart';
import '../../../core/services/minutecast/minutecast_config.dart';
import '../../../core/services/minutecast/minutecast_exceptions.dart';

/// Every state the MinuteCast section can be in. The weather screen must
/// never fail because of MinuteCast, so this deliberately has no "error"
/// variant that could propagate as an [AsyncError] — every failure mode
/// resolves to [MinuteCastUnavailable] instead.
sealed class MinuteCastAvailability {
  const MinuteCastAvailability();
}

/// Fresh (or recently-fetched) data, safe to show without qualification.
class MinuteCastAvailable extends MinuteCastAvailability {
  const MinuteCastAvailable(this.data);

  final MinuteCast data;
}

/// Still within the usable cache window, but old enough that a background
/// refresh is warranted/in flight — the UI may choose to show this more
/// quietly than [MinuteCastAvailable], but it is never hidden or treated
/// as an error.
class MinuteCastStale extends MinuteCastAvailability {
  const MinuteCastStale(this.data, this.ageMinutes);

  final MinuteCast data;
  final int ageMinutes;
}

enum MinuteCastUnavailableReason {
  /// No API key configured — a permanent, quiet "not set up" state.
  notConfigured,

  /// A fetch failed (network/timeout/server/parse/rate-limit) and there
  /// is no usable cache to fall back to.
  temporaryError,

  /// The only cached data available is older than
  /// [MinuteCastConfig.maxCacheAge] — never shown, to avoid displaying a
  /// dangerously stale "starting in N min".
  cacheTooOld,
}

/// No usable data — the section should hide itself or show a small,
/// unobtrusive note, never a large error card.
class MinuteCastUnavailable extends MinuteCastAvailability {
  const MinuteCastUnavailable(this.reason);

  final MinuteCastUnavailableReason reason;
}

/// Drives MinuteCast for one [Location]: cache-immediately-then-refresh-
/// quietly on first read (mirroring `WeatherController`), a periodic
/// [ensureFresh] the UI calls on its own ~5-minute timer while visible,
/// and the same "location change gets its own instance" behavior every
/// other `.family` controller in this app already has. Every failure
/// mode is caught here and turned into [MinuteCastUnavailable] — nothing
/// above this ever sees a [MinuteCastException].
class MinuteCastController extends AsyncNotifier<MinuteCastAvailability> {
  MinuteCastController(this.location);

  final Location location;

  @override
  Future<MinuteCastAvailability> build() async {
    final repo = ref.watch(minuteCastRepositoryProvider);
    final cached = await repo.getCached(location);
    final now = DateTime.now();

    if (cached != null && !_tooOldToShow(cached, now)) {
      if (_needsRefresh(cached, now)) {
        unawaited(_refreshQuietly(repo));
      }
      return _availabilityFor(cached, now);
    }

    return _fetchFresh(repo, hadTooOldCache: cached != null);
  }

  /// Called by the UI on its own timer while the MinuteCast section is
  /// visible (never in the background) — a no-op if the current data is
  /// already fresh enough.
  Future<void> ensureFresh() async {
    final current = state.value;
    final now = DateTime.now();
    final currentData = switch (current) {
      MinuteCastAvailable(:final data) => data,
      MinuteCastStale(:final data) => data,
      MinuteCastUnavailable() || null => null,
    };
    if (currentData != null && !_needsRefresh(currentData, now)) return;

    final repo = ref.read(minuteCastRepositoryProvider);
    await _refreshQuietly(repo);
  }

  Future<MinuteCastAvailability> _fetchFresh(MinuteCastRepository repo, {bool hadTooOldCache = false}) async {
    try {
      final data = await repo.fetchAndCache(location);
      return MinuteCastAvailable(data);
    } on MinuteCastNotConfiguredException {
      return const MinuteCastUnavailable(MinuteCastUnavailableReason.notConfigured);
    } on MinuteCastException {
      return MinuteCastUnavailable(
        hadTooOldCache ? MinuteCastUnavailableReason.cacheTooOld : MinuteCastUnavailableReason.temporaryError,
      );
    }
  }

  Future<void> _refreshQuietly(MinuteCastRepository repo) async {
    try {
      final fresh = await repo.fetchAndCache(location);
      if (ref.mounted) state = AsyncData(MinuteCastAvailable(fresh));
    } catch (_) {
      // Whatever's already on screen (available or stale-but-usable
      // cached data) stays there; a background refresh failing is not
      // worth surfacing on a secondary feature like this one.
    }
  }

  bool _tooOldToShow(MinuteCast data, DateTime now) {
    return data.isStaleAsOf(now, threshold: MinuteCastConfig.maxCacheAge);
  }

  bool _needsRefresh(MinuteCast data, DateTime now) {
    return now.difference(data.generatedAt) > MinuteCastConfig.refreshInterval;
  }

  MinuteCastAvailability _availabilityFor(MinuteCast data, DateTime now) {
    final age = now.difference(data.generatedAt);
    if (age > MinuteCastConfig.refreshInterval) {
      return MinuteCastStale(data, age.inMinutes);
    }
    return MinuteCastAvailable(data);
  }
}

final minuteCastControllerProvider = AsyncNotifierProvider.family<MinuteCastController, MinuteCastAvailability, Location>(
  MinuteCastController.new,
);
