import 'package:equatable/equatable.dart';

import '../../utils/location_time.dart';
import 'minute_cast.dart';
import 'minute_cast_thresholds.dart';
import 'minute_precipitation_forecast.dart';

/// Which of the four conditions a [MinuteCastSummary] describes —
/// "currently precipitating" (no end visible in the data),
/// "precipitation approaching", "precipitation ending" (an end *is*
/// visible), and "no precipitation expected".
enum MinuteCastState { dry, approaching, active, ending }

/// Natural-language copy for a [MinuteCast], derived entirely from its
/// minute data — never a hardcoded string picked ahead of time. See
/// [summarizeMinuteCast] for exactly how each phrase is chosen.
class MinuteCastSummary extends Equatable {
  const MinuteCastSummary({required this.state, required this.headline, this.subtitle});

  final MinuteCastState state;

  /// e.g. `"Rain starting in 13 min"`, `"Dry for the next hour"`.
  final String headline;

  /// e.g. `"Light rain · 10:51–11:24"` — only present when the data
  /// actually supports it (see [summarizeMinuteCast]); never a guess.
  final String? subtitle;

  @override
  List<Object?> get props => [state, headline, subtitle];
}

/// Derives natural-language MinuteCast copy from raw minute data as of
/// [now]. This is the *only* place MinuteCast wording is decided — the
/// UI just renders whatever this returns.
///
/// Core rules (see [MinuteCastThresholds] for the numeric bands):
/// - A minute counts as "precipitating" once its rate clears
///   [MinuteCastThresholds.dryMmPerHour] — nothing below that is ever
///   described as rain/snow starting, ending, or ongoing.
/// - "Ending" is only reported once the data shows
///   [MinuteCastThresholds.endingPersistenceMinutes] consecutive dry
///   minutes *within the data actually available* — a single dry-looking
///   minute inside an active event does not flip the summary to
///   "ending", and if the window runs out before three dry minutes are
///   confirmed, this reports "continuing" rather than guessing an end.
/// - Anything within [MinuteCastThresholds.nowThresholdMinutes] minutes
///   collapses to "now"/"soon" rather than claiming false precision
///   ("starting in 1 min").
/// - "N minutes away" is always computed relative to [now], not to the
///   data's own first entry — so a summary built from a few-minutes-old
///   cached snapshot still reads correctly when it's actually shown.
///
/// [timeZone] is the location's IANA time zone (see
/// `core/utils/location_time.dart`) — the subtitle's clock times are
/// rendered in *that* zone, not the device's, since a saved location is
/// not necessarily in the same time zone as the device checking it. Null
/// falls back to the device's local time zone (the same degraded-but-safe
/// behavior every other time display in this app has today).
MinuteCastSummary summarizeMinuteCast(List<MinutePrecipitationForecast> minutes, DateTime now, {String? timeZone}) {
  if (minutes.isEmpty) {
    return const MinuteCastSummary(state: MinuteCastState.dry, headline: 'Dry for the next hour');
  }

  // The minute that best represents "right now" — the last one at or
  // before `now`, falling back to the first minute if the whole window
  // is still ahead of `now` (e.g. a snapshot fetched fractionally early).
  var currentIndex = 0;
  for (var i = 0; i < minutes.length; i++) {
    if (!minutes[i].time.isAfter(now)) {
      currentIndex = i;
    } else {
      break;
    }
  }

  final isCurrentlyWet = minutes[currentIndex].isMeaningfulPrecipitation;

  if (isCurrentlyWet) {
    final dryRunStart = _findConfirmedDryRun(minutes, from: currentIndex + 1);
    if (dryRunStart == null) {
      final type = _dominantType(minutes, currentIndex, minutes.length);
      final intensity = _peakIntensity(minutes, currentIndex, minutes.length);
      return MinuteCastSummary(
        state: MinuteCastState.active,
        headline: '${_typeLabel(type, capitalize: true)} continuing for the next hour',
        subtitle: '${_intensityLabel(intensity)} ${_typeLabel(type)}',
      );
    }

    final endMinutesAway = _minutesAway(minutes[dryRunStart].time, now);
    final type = _dominantType(minutes, currentIndex, dryRunStart);
    final intensity = _peakIntensity(minutes, currentIndex, dryRunStart);
    final headline = endMinutesAway <= MinuteCastThresholds.nowThresholdMinutes
        ? '${_typeLabel(type, capitalize: true)} ending soon'
        : '${_typeLabel(type, capitalize: true)} ending in $endMinutesAway min';
    return MinuteCastSummary(
      state: MinuteCastState.ending,
      headline: headline,
      subtitle: '${_intensityLabel(intensity)} ${_typeLabel(type)}',
    );
  }

  final startIndex = _findFirstWet(minutes, from: currentIndex + 1);
  if (startIndex == null) {
    return const MinuteCastSummary(state: MinuteCastState.dry, headline: 'Dry for the next hour');
  }

  final startMinutesAway = _minutesAway(minutes[startIndex].time, now);
  final type = minutes[startIndex].type;
  final headline = startMinutesAway <= MinuteCastThresholds.nowThresholdMinutes
      ? '${_typeLabel(type, capitalize: true)} starting now'
      : '${_typeLabel(type, capitalize: true)} starting in $startMinutesAway min';

  final dryRunStart = _findConfirmedDryRun(minutes, from: startIndex + 1);
  final String subtitle;
  if (dryRunStart != null) {
    final intensity = _peakIntensity(minutes, startIndex, dryRunStart);
    final startLabel = formatClockTimeCompact(minutes[startIndex].time, timeZone);
    final endLabel = formatClockTimeCompact(minutes[dryRunStart].time, timeZone);
    subtitle = '${_intensityLabel(intensity)} ${_typeLabel(type)} · $startLabel–$endLabel';
  } else {
    final intensity = _peakIntensity(minutes, startIndex, minutes.length);
    subtitle = '${_intensityLabel(intensity)} ${_typeLabel(type)}';
  }

  return MinuteCastSummary(state: MinuteCastState.approaching, headline: headline, subtitle: subtitle);
}

/// The index of the first minute of a run of
/// [MinuteCastThresholds.endingPersistenceMinutes] consecutive dry
/// minutes starting at or after [from] — or null if no such fully-confirmed
/// run exists within the data (including when a dry stretch is still
/// running when the data simply ends, which is deliberately *not*
/// treated as confirmed).
int? _findConfirmedDryRun(List<MinutePrecipitationForecast> minutes, {required int from}) {
  final needed = MinuteCastThresholds.endingPersistenceMinutes;
  for (var i = from; i <= minutes.length - needed; i++) {
    final allDry = List.generate(needed, (j) => i + j).every((k) => !minutes[k].isMeaningfulPrecipitation);
    if (allDry) return i;
  }
  return null;
}

int? _findFirstWet(List<MinutePrecipitationForecast> minutes, {required int from}) {
  for (var i = from; i < minutes.length; i++) {
    if (minutes[i].isMeaningfulPrecipitation) return i;
  }
  return null;
}

int _minutesAway(DateTime time, DateTime now) {
  final minutes = (time.difference(now).inSeconds / 60).round();
  return minutes < 0 ? 0 : minutes;
}

PrecipitationType _dominantType(List<MinutePrecipitationForecast> minutes, int start, int end) {
  final counts = <PrecipitationType, int>{};
  for (var i = start; i < end; i++) {
    final type = minutes[i].type;
    if (type == PrecipitationType.none) continue;
    counts[type] = (counts[type] ?? 0) + 1;
  }
  if (counts.isEmpty) return minutes[start].type;
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

PrecipitationIntensity _peakIntensity(List<MinutePrecipitationForecast> minutes, int start, int end) {
  var peak = PrecipitationIntensity.none;
  for (var i = start; i < end; i++) {
    final category = minutes[i].intensityCategory;
    if (category.index > peak.index) peak = category;
  }
  return peak;
}

String _typeLabel(PrecipitationType type, {bool capitalize = false}) {
  final label = switch (type) {
    PrecipitationType.rain => 'rain',
    PrecipitationType.snow => 'snow',
    PrecipitationType.sleet => 'sleet',
    PrecipitationType.unknown => 'precipitation',
    PrecipitationType.none => 'precipitation',
  };
  if (!capitalize) return label;
  return label[0].toUpperCase() + label.substring(1);
}

String _intensityLabel(PrecipitationIntensity intensity) {
  return switch (intensity) {
    PrecipitationIntensity.none => 'Light',
    PrecipitationIntensity.light => 'Light',
    PrecipitationIntensity.moderate => 'Moderate',
    PrecipitationIntensity.heavy => 'Heavy',
  };
}
