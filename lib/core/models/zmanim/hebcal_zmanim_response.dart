import 'hebcal_zman_field.dart';

/// Raw parse of a single Hebcal `/zmanim?cfg=json` response for one day —
/// mirrors `NwsForecast`'s role for the weather pipeline: this is the only
/// place that knows Hebcal's JSON shape. `times` only contains entries for
/// fields Hebcal actually returned and that [HebcalZmanField] recognizes;
/// a field Hebcal omits for the day/location (e.g. a zman that doesn't
/// occur at an extreme latitude) or a field Hebcal adds in the future and
/// this app doesn't know about yet is simply absent, never a crash.
class HebcalZmanimResponse {
  const HebcalZmanimResponse({required this.times});

  final Map<HebcalZmanField, DateTime> times;

  static HebcalZmanimResponse? tryParse(Map<String, dynamic> json) {
    final timesJson = json['times'];
    if (timesJson is! Map) return null;

    final times = <HebcalZmanField, DateTime>{};
    for (final entry in timesJson.entries) {
      final field = HebcalZmanField.tryParse(entry.key as String?);
      if (field == null) continue;
      final raw = entry.value;
      if (raw is! String) continue;
      final time = DateTime.tryParse(raw);
      if (time == null) continue;
      times[field] = time;
    }

    if (times.isEmpty) return null;
    return HebcalZmanimResponse(times: times);
  }
}
