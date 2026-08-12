import 'package:equatable/equatable.dart';

import 'hebcal_zman_field.dart';
import 'zman_definition.dart';

/// The app's approved default 12 Zmanim, in the exact order/display names
/// specified for V1, each mapped to a real Hebcal field verified against
/// Hebcal's own API source (see `HebcalZmanField`) -- never an invented
/// field. Where Hebcal offers multiple halachic opinions for a zman, the
/// choice made here is documented so it's a visible, intentional default
/// rather than an arbitrary one:
///   - Alos -> `alotHaShachar` (16.1°), Hebcal's standard dawn definition;
///     `alosBaalHatanya` is offered as an alternate in Advanced settings.
///   - Earliest Tallis and Tefillin -> `misheyakir` (11.5°), the common
///     definition; `misheyakirMachmir` (10.2°, stricter) is an alternate.
///   - Netz -> `sunrise` (standard, not sea-level-adjusted).
///   - Sof Zman Krias Shema MG"A -> `sofZmanShmaMGA` (72-minute model);
///     the 16.1°/19.8°/Baal Hatanya variants are alternates.
///   - Sof Zman Krias Shema GRA -> `sofZmanShma`.
///   - Sof Zman Tefilla -> `sofZmanTfilla` (Gra); the MGA/Baal Hatanya
///     variants are alternates, matching the same GRA-default pattern
///     used for Mincha Gedola/Ketana and Plag below.
///   - Chatzos -> `chatzot`.
///   - Mincha Gedola -> `minchaGedola` (Gra).
///   - Mincha Ketana -> `minchaKetana` (Gra).
///   - Plag HaMincha -> `plagHaMincha` (Gra).
///   - Shkia -> `sunset` (standard, not sea-level-adjusted).
///   - Tzeis -> `tzeit7083deg` (3 medium stars / 7.083°) -- the first and
///     most commonly displayed of Hebcal's five tzeit variants; 8.5°,
///     42/50/72-minute, and Baal Hatanya are alternates.
const List<ZmanDefinition> defaultZmanDefinitions = [
  ZmanDefinition(id: 'alos', displayName: 'Alos', field: HebcalZmanField.alotHaShachar),
  ZmanDefinition(
    id: 'earliest_tallis_tefillin',
    displayName: 'Earliest Tallis and Tefillin',
    field: HebcalZmanField.misheyakir,
  ),
  ZmanDefinition(id: 'netz', displayName: 'Netz', field: HebcalZmanField.sunrise),
  ZmanDefinition(
    id: 'sof_zman_shema_mga',
    displayName: 'Sof Zman Krias Shema MG"A',
    field: HebcalZmanField.sofZmanShmaMGA,
  ),
  ZmanDefinition(
    id: 'sof_zman_shema_gra',
    displayName: 'Sof Zman Krias Shema GRA',
    field: HebcalZmanField.sofZmanShma,
  ),
  ZmanDefinition(id: 'sof_zman_tefilla', displayName: 'Sof Zman Tefilla', field: HebcalZmanField.sofZmanTfilla),
  ZmanDefinition(id: 'chatzos', displayName: 'Chatzos', field: HebcalZmanField.chatzot),
  ZmanDefinition(id: 'mincha_gedola', displayName: 'Mincha Gedola', field: HebcalZmanField.minchaGedola),
  ZmanDefinition(id: 'mincha_ketana', displayName: 'Mincha Ketana', field: HebcalZmanField.minchaKetana),
  ZmanDefinition(id: 'plag_hamincha', displayName: 'Plag HaMincha', field: HebcalZmanField.plagHaMincha),
  ZmanDefinition(id: 'shkia', displayName: 'Shkia', field: HebcalZmanField.sunset),
  ZmanDefinition(id: 'tzeis', displayName: 'Tzeis', field: HebcalZmanField.tzeit7083deg),
];

/// Every Hebcal field the default 12 don't already use, offered as
/// ready-to-add rows in Advanced Zmanim settings (see requirement to
/// support "adding additional Zmanim available from Hebcal beyond the
/// default 12" without inventing calculation options Hebcal doesn't
/// provide). Each `id` is unique against [defaultZmanDefinitions] and
/// against every other entry here, so a template can be added directly
/// as-is; the user can still rename it afterward like any other row.
const List<ZmanDefinition> additionalZmanTemplates = [
  ZmanDefinition(id: 'chatzot_night', displayName: 'Chatzos (Night)', field: HebcalZmanField.chatzotNight),
  ZmanDefinition(id: 'alos_baal_hatanya', displayName: 'Alos (Baal HaTanya)', field: HebcalZmanField.alosBaalHatanya),
  ZmanDefinition(
    id: 'misheyakir_machmir',
    displayName: 'Earliest Tallis and Tefillin (Machmir)',
    field: HebcalZmanField.misheyakirMachmir,
  ),
  ZmanDefinition(id: 'dawn', displayName: 'Dawn (Civil, 6°)', field: HebcalZmanField.dawn),
  ZmanDefinition(id: 'netz_sea_level', displayName: 'Netz (Sea Level)', field: HebcalZmanField.seaLevelSunrise),
  ZmanDefinition(
    id: 'sof_zman_shema_mga_16_1',
    displayName: 'Sof Zman Krias Shema MG"A (16.1°)',
    field: HebcalZmanField.sofZmanShmaMGA16Point1,
  ),
  ZmanDefinition(
    id: 'sof_zman_shema_mga_19_8',
    displayName: 'Sof Zman Krias Shema MG"A (19.8°)',
    field: HebcalZmanField.sofZmanShmaMGA19Point8,
  ),
  ZmanDefinition(
    id: 'sof_zman_shema_baal_hatanya',
    displayName: 'Sof Zman Krias Shema (Baal HaTanya)',
    field: HebcalZmanField.sofZmanShmaBaalHatanya,
  ),
  ZmanDefinition(
    id: 'sof_zman_tefilla_mga',
    displayName: 'Sof Zman Tefilla MG"A',
    field: HebcalZmanField.sofZmanTfillaMGA,
  ),
  ZmanDefinition(
    id: 'sof_zman_tefilla_mga_16_1',
    displayName: 'Sof Zman Tefilla MG"A (16.1°)',
    field: HebcalZmanField.sofZmanTfillaMGA16Point1,
  ),
  ZmanDefinition(
    id: 'sof_zman_tefilla_mga_19_8',
    displayName: 'Sof Zman Tefilla MG"A (19.8°)',
    field: HebcalZmanField.sofZmanTfillaMGA19Point8,
  ),
  ZmanDefinition(
    id: 'sof_zman_tefilla_baal_hatanya',
    displayName: 'Sof Zman Tefilla (Baal HaTanya)',
    field: HebcalZmanField.sofZmanTfilaBaalHatanya,
  ),
  ZmanDefinition(
    id: 'mincha_gedola_mga',
    displayName: 'Mincha Gedola (MG"A)',
    field: HebcalZmanField.minchaGedolaMGA,
  ),
  ZmanDefinition(
    id: 'mincha_gedola_baal_hatanya',
    displayName: 'Mincha Gedola (Baal HaTanya)',
    field: HebcalZmanField.minchaGedolaBaalHatanya,
  ),
  ZmanDefinition(
    id: 'mincha_ketana_mga',
    displayName: 'Mincha Ketana (MG"A)',
    field: HebcalZmanField.minchaKetanaMGA,
  ),
  ZmanDefinition(
    id: 'mincha_ketana_baal_hatanya',
    displayName: 'Mincha Ketana (Baal HaTanya)',
    field: HebcalZmanField.minchaKetanaBaalHatanya,
  ),
  ZmanDefinition(
    id: 'plag_hamincha_baal_hatanya',
    displayName: 'Plag HaMincha (Baal HaTanya)',
    field: HebcalZmanField.plagHaminchaBaalHatanya,
  ),
  ZmanDefinition(id: 'shkia_sea_level', displayName: 'Shkia (Sea Level)', field: HebcalZmanField.seaLevelSunset),
  ZmanDefinition(id: 'bein_hashmashos', displayName: 'Bein HaShmashos', field: HebcalZmanField.beinHaShmashos),
  ZmanDefinition(id: 'dusk', displayName: 'Dusk (Civil, 6°)', field: HebcalZmanField.dusk),
  ZmanDefinition(
    id: 'tzeis_baal_hatanya',
    displayName: 'Tzeis (Baal HaTanya)',
    field: HebcalZmanField.tzaisBaalHatanya,
  ),
  ZmanDefinition(id: 'tzeis_85deg', displayName: 'Tzeis (8.5°)', field: HebcalZmanField.tzeit85deg),
  ZmanDefinition(id: 'tzeis_42min', displayName: 'Tzeis (42 Minutes)', field: HebcalZmanField.tzeit42min),
  ZmanDefinition(id: 'tzeis_50min', displayName: 'Tzeis (50 Minutes)', field: HebcalZmanField.tzeit50min),
  ZmanDefinition(
    id: 'tzeis_72min',
    displayName: 'Tzeis (72 Minutes, Rabbeinu Tam)',
    field: HebcalZmanField.tzeit72min,
  ),
];

/// The user's full Zmanim display configuration: which rows exist, their
/// display names, which Hebcal calculation backs each, whether each is
/// shown, and their order (list position). This is pure display/selection
/// configuration -- it never talks to Hebcal directly (see
/// `core/repositories/zmanim_repository.dart` for that) and the raw
/// Hebcal response never talks to this (see `Zmanim`/`HebcalZmanimResponse`).
class ZmanimConfiguration extends Equatable {
  const ZmanimConfiguration({required this.definitions});

  factory ZmanimConfiguration.defaults() => const ZmanimConfiguration(definitions: defaultZmanDefinitions);

  final List<ZmanDefinition> definitions;

  Map<String, dynamic> toJson() => {
        'definitions': definitions.map((d) => d.toJson()).toList(),
      };

  /// Falls back to [ZmanimConfiguration.defaults] on any malformed input
  /// rather than crashing -- a corrupt or pre-migration preferences entry
  /// should never take Zmanim off the screen entirely.
  static ZmanimConfiguration tryFromJson(Map<String, dynamic> json) {
    final defsJson = json['definitions'];
    if (defsJson is! List) return ZmanimConfiguration.defaults();
    final definitions = defsJson
        .whereType<Map<String, dynamic>>()
        .map(ZmanDefinition.tryFromJson)
        .whereType<ZmanDefinition>()
        .toList();
    if (definitions.isEmpty) return ZmanimConfiguration.defaults();
    return ZmanimConfiguration(definitions: definitions);
  }

  @override
  List<Object?> get props => [definitions];
}
