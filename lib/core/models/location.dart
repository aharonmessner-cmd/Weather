import 'package:equatable/equatable.dart';

/// A saved place the user wants weather for.
///
/// Weather is always resolved from [latitude]/[longitude] — [name] is
/// purely a user-facing label and is never sent to NWS or used to look up
/// weather data.
class Location extends Equatable {
  const Location({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.description,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? description;
  final bool isFavorite;

  static const _unset = Object();

  /// [address] and [description] are nullable fields the caller may want to
  /// *clear*, so they use a sentinel default rather than `??`: passing an
  /// explicit `null` clears the field, while omitting the argument leaves
  /// it unchanged.
  Location copyWith({
    String? name,
    double? latitude,
    double? longitude,
    Object? address = _unset,
    Object? description = _unset,
    bool? isFavorite,
  }) {
    return Location(
      id: id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: identical(address, _unset) ? this.address : address as String?,
      description: identical(description, _unset) ? this.description : description as String?,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'description': description,
        'isFavorite': isFavorite,
      };

  static Location? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    if (id is! String || name is! String || latitude is! num || longitude is! num) {
      return null;
    }
    return Location(
      id: id,
      name: name,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      address: json['address'] as String?,
      description: json['description'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, latitude, longitude, address, description, isFavorite];
}
