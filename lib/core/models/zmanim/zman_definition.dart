import 'package:equatable/equatable.dart';

import 'hebcal_zman_field.dart';

/// One configurable row in the Zmanim card: a stable identity, a
/// user-facing display name (independent of Hebcal's field name), which
/// Hebcal calculation currently backs it, and whether it's shown at all.
///
/// Ordering is deliberately *not* a field here — it's expressed by this
/// definition's position in `ZmanimConfiguration.definitions`, so there is
/// exactly one source of truth for order (the list itself) rather than an
/// index that could drift out of sync with it.
class ZmanDefinition extends Equatable {
  const ZmanDefinition({
    required this.id,
    required this.displayName,
    required this.field,
    this.enabled = true,
  });

  /// Stable internal identifier (e.g. `'alos'`) — survives display-name
  /// edits and Hebcal-field swaps, used as the row identity everywhere
  /// (persistence, "current/next zman" tracking, widget keys).
  final String id;

  /// The app's canonical display name, editable by the user in Advanced
  /// Zmanim settings. Never a Hebcal field name — see the module doc on
  /// `HebcalZmanField` for why those stay out of the presentation layer.
  final String displayName;

  /// Which Hebcal calculation/opinion currently powers this row. Changing
  /// this (e.g. GRA -> MGA for the same named row) is an explicit,
  /// visible choice in Advanced Zmanim settings — never silent.
  final HebcalZmanField field;

  final bool enabled;

  ZmanDefinition copyWith({String? displayName, HebcalZmanField? field, bool? enabled}) {
    return ZmanDefinition(
      id: id,
      displayName: displayName ?? this.displayName,
      field: field ?? this.field,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'field': field.apiKey,
        'enabled': enabled,
      };

  static ZmanDefinition? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final displayName = json['displayName'];
    final field = HebcalZmanField.tryParse(json['field'] as String?);
    if (id is! String || displayName is! String || field == null) return null;
    return ZmanDefinition(
      id: id,
      displayName: displayName,
      field: field,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, displayName, field, enabled];
}
