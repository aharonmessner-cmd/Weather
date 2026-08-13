import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/models/allergy/allergy_data.dart';
import '../../../core/models/location.dart';
import '../../../core/repositories/allergy_repository.dart';
import '../../../core/services/allergy/allergy_config.dart';
import '../../../core/services/allergy/allergy_exceptions.dart';

/// Every state the Allergies card can be in. The weather screen must
/// never fail because of this feature, so this deliberately has no
/// "error" variant that could propagate as an [AsyncError] — every
/// failure mode resolves to [AllergyUnavailable] instead. Mirrors
/// `MinuteCastAvailability`.
sealed class AllergyAvailability {
  const AllergyAvailability();
}

/// Fresh (or recently-fetched) data, safe to show without qualification.
class AllergyAvailable extends AllergyAvailability {
  const AllergyAvailable(this.data);

  final AllergyData data;
}

/// Still within the usable cache window, but old enough that a background
/// refresh is warranted/in flight.
class AllergyStale extends AllergyAvailability {
  const AllergyStale(this.data, this.ageMinutes);

  final AllergyData data;
  final int ageMinutes;
}

enum AllergyUnavailableReason {
  /// A fetch failed (network/timeout/server/parse/rate-limit) and there
  /// is no usable cache to fall back to.
  temporaryError,

  /// The only cached data available is older than
  /// [AllergyConfig.maxCacheAge].
  cacheTooOld,
}

/// No usable data — the card should simply not render, never show a
/// large error state.
class AllergyUnavailable extends AllergyAvailability {
  const AllergyUnavailable(this.reason);

  final AllergyUnavailableReason reason;
}

/// Drives the Allergies card for one [Location]: cache-immediately-then-
/// refresh-quietly on first read, mirroring `MinuteCastController` (and,
/// through it, `WeatherController`). Every failure mode is caught here
/// and turned into [AllergyUnavailable] — nothing above this ever sees an
/// [AllergyException].
class AllergyController extends AsyncNotifier<AllergyAvailability> {
  AllergyController(this.location);

  final Location location;

  @override
  Future<AllergyAvailability> build() async {
    final repo = ref.watch(allergyRepositoryProvider);
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

  Future<AllergyAvailability> _fetchFresh(AllergyRepository repo, {bool hadTooOldCache = false}) async {
    try {
      final data = await repo.fetchAndCache(location);
      return AllergyAvailable(data);
    } on AllergyException {
      return AllergyUnavailable(
        hadTooOldCache ? AllergyUnavailableReason.cacheTooOld : AllergyUnavailableReason.temporaryError,
      );
    }
  }

  Future<void> _refreshQuietly(AllergyRepository repo) async {
    try {
      final fresh = await repo.fetchAndCache(location);
      if (ref.mounted) state = AsyncData(AllergyAvailable(fresh));
    } catch (_) {
      // Whatever's already on screen (available or stale-but-usable
      // cached data) stays there; a background refresh failing is not
      // worth surfacing on a secondary feature like this one.
    }
  }

  bool _tooOldToShow(AllergyData data, DateTime now) {
    return data.isStaleAsOf(now, threshold: AllergyConfig.maxCacheAge);
  }

  bool _needsRefresh(AllergyData data, DateTime now) {
    return now.difference(data.generatedAt) > AllergyConfig.refreshInterval;
  }

  AllergyAvailability _availabilityFor(AllergyData data, DateTime now) {
    final age = now.difference(data.generatedAt);
    if (age > AllergyConfig.refreshInterval) {
      return AllergyStale(data, age.inMinutes);
    }
    return AllergyAvailable(data);
  }
}

final allergyControllerProvider = AsyncNotifierProvider.family<AllergyController, AllergyAvailability, Location>(
  AllergyController.new,
);
