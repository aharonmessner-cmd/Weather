import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/zmanim_settings_controller.dart';
import '../../../core/models/location.dart';
import '../../../core/models/zmanim/zman.dart';
import '../../../core/models/zmanim/zman_selection.dart';
import '../../../core/models/zmanim/zmanim_configuration.dart';
import '../../../core/repositories/zmanim_repository.dart';
import '../../../core/services/zmanim/zmanim_exceptions.dart';

/// A location plus the time zone Zmanim should be computed in -- both are
/// needed as the family key, since (unlike `MinuteCastController`) Zmanim
/// also needs to know when it has *no* usable zone yet (see
/// [ZmanimUnavailableReason.noLocationTimeZone]).
typedef ZmanimQuery = ({Location location, String? timeZone});

/// Every state the Zmanim section can be in. Mirrors
/// `MinuteCastController`'s never-surface-an-error philosophy: the
/// weather screen must never fail because of Zmanim, so every failure
/// mode resolves to [ZmanimUnavailable] instead of an [AsyncError].
sealed class ZmanimAvailability {
  const ZmanimAvailability();
}

/// The full configured, enabled Zmanim list for today -- *not* filtered
/// to "still upcoming" here. That filtering is time-based and re-derived
/// continuously at render time (see `ZmanimSection`), not baked into
/// this state, so rows disappear as time passes without needing a
/// rebuild of this controller.
class ZmanimAvailable extends ZmanimAvailability {
  const ZmanimAvailable(this.zmanim);

  final List<Zman> zmanim;
}

enum ZmanimUnavailableReason {
  /// [ZmanimQuery.timeZone] is null -- no location time zone is known yet
  /// (e.g. cached weather data from before locations carried one), so
  /// there's nothing safe to ask Hebcal for. Never guesses the device's
  /// zone for a remote saved location.
  noLocationTimeZone,

  /// A fetch failed (network/timeout/server/parse/rate-limit) and there
  /// is no usable cache to fall back to.
  temporaryError,
}

class ZmanimUnavailable extends ZmanimAvailability {
  const ZmanimUnavailable(this.reason);

  final ZmanimUnavailableReason reason;
}

/// Drives Zmanim for one [ZmanimQuery]: cache-immediately-then-refresh-
/// quietly on first read (mirroring `MinuteCastController`/
/// `WeatherController`), and an [ensureFresh] the UI calls on its own
/// low-frequency local timer -- which only touches the network when the
/// location-local calendar date has actually rolled over (no API call is
/// ever made just to re-check the time of day). Also rebuilds whenever
/// [zmanimConfigurationProvider] changes, entirely client-side (see
/// `selectZmanim` -- a single Hebcal fetch already contains every field
/// it computes for the day, so changing which rows/calculations are
/// shown never needs a new network request on its own).
class ZmanimController extends AsyncNotifier<ZmanimAvailability> {
  ZmanimController(this.query);

  final ZmanimQuery query;

  Location get location => query.location;
  String? get timeZone => query.timeZone;

  @override
  Future<ZmanimAvailability> build() async {
    final tz = timeZone;
    if (tz == null) return const ZmanimUnavailable(ZmanimUnavailableReason.noLocationTimeZone);

    // Rebuilding whenever the configuration changes is what makes
    // enabling/disabling/reordering/re-mapping a row take effect
    // immediately, with no network call unless the cache below is also
    // empty for today.
    final config = ref.watch(zmanimConfigurationProvider);
    final repo = ref.watch(zmanimRepositoryProvider);

    final cached = await repo.getCached(location, tz);
    if (cached != null) {
      return ZmanimAvailable(selectZmanim(cached, config));
    }

    return _fetchFresh(repo, tz, config);
  }

  /// Called by the UI on its own low-frequency timer while the Zmanim
  /// section is visible -- a no-op (no network call) unless today's
  /// cached snapshot is missing, which only happens right after the
  /// location-local calendar date rolls over or on the very first load.
  Future<void> ensureFresh() async {
    final tz = timeZone;
    if (tz == null) return;

    final repo = ref.read(zmanimRepositoryProvider);
    final cached = await repo.getCached(location, tz);
    if (cached != null) return;

    final config = ref.read(zmanimConfigurationProvider);
    await _refreshQuietly(repo, tz, config);
  }

  Future<ZmanimAvailability> _fetchFresh(ZmanimRepository repo, String tz, ZmanimConfiguration config) async {
    try {
      final data = await repo.fetchAndCache(location, tz);
      return ZmanimAvailable(selectZmanim(data, config));
    } on ZmanimException {
      return const ZmanimUnavailable(ZmanimUnavailableReason.temporaryError);
    }
  }

  Future<void> _refreshQuietly(ZmanimRepository repo, String tz, ZmanimConfiguration config) async {
    try {
      final fresh = await repo.fetchAndCache(location, tz);
      if (ref.mounted) state = AsyncData(ZmanimAvailable(selectZmanim(fresh, config)));
    } catch (_) {
      // Whatever's already on screen stays there; a background refresh
      // failing is not worth surfacing on a secondary feature like this.
    }
  }
}

final zmanimControllerProvider =
    AsyncNotifierProvider.family<ZmanimController, ZmanimAvailability, ZmanimQuery>(ZmanimController.new);
