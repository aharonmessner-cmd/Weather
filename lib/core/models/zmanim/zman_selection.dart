import 'zman.dart';
import 'zmanim.dart';
import 'zmanim_configuration.dart';

/// Applies a user's [ZmanimConfiguration] to a raw [Zmanim] snapshot,
/// entirely client-side — no network call, since a single Hebcal response
/// already contains every field it computes for that day/location. This
/// is the *only* place display configuration and raw provider data meet;
/// everything above this works with plain [Zman]s, everything below it
/// works with [HebcalZmanField]s, and neither layer knows about the other.
///
/// Order matches [ZmanimConfiguration.definitions]' list order. A
/// definition whose field Hebcal didn't return for this day/location
/// (e.g. an extreme-latitude edge case) is silently omitted rather than
/// shown with a missing time.
List<Zman> selectZmanim(Zmanim data, ZmanimConfiguration config) {
  final result = <Zman>[];
  for (final definition in config.definitions) {
    if (!definition.enabled) continue;
    final time = data.times[definition.field];
    if (time == null) continue;
    result.add(Zman(id: definition.id, displayName: definition.displayName, time: time));
  }
  return result;
}

/// Narrows [zmanim] to the ones still ahead of [now] -- a plain filter on
/// absolute instants, deliberately the same semantics as
/// `HourlyForecastEntry.upcomingFrom`: a zman *at* [now] counts as already
/// passed (`isAfter` is strict), and this needs no separate time-zone
/// conversion step to be correct, since [DateTime] comparison is
/// instant-based regardless of what zone either value happens to carry.
/// Display-time formatting (which *does* need the location's zone) is a
/// separate, later step -- see `core/utils/location_time.dart`.
List<Zman> remainingZmanim(List<Zman> zmanim, DateTime now) {
  return zmanim.where((z) => z.time.isAfter(now)).toList();
}
