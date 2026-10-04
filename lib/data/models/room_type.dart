/// Global catalog of room types offered on every hotel. Each type is a
/// multiplier applied to the hotel's base pricePerNight — there is no
/// per-hotel room type data; every hotel offers the same 3 tiers.
enum RoomType { regular, premium, luxury }

extension RoomTypeInfo on RoomType {
  String get label => switch (this) {
        RoomType.regular => 'Regular',
        RoomType.premium => 'Premium',
        RoomType.luxury => 'Luxury',
      };

  double get priceMultiplier => switch (this) {
        RoomType.regular => 1.0,
        RoomType.premium => 1.3,
        RoomType.luxury => 1.7,
      };

  String get description => switch (this) {
        RoomType.regular => 'Comfortable essentials for your stay',
        RoomType.premium => 'Extra space and upgraded amenities',
        RoomType.luxury => 'Our most spacious, premium option',
      };
}
