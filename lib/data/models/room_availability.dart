import 'room_type.dart';

/// Per-room-type room counts for a hotel (catalog or host-listed). Live
/// counts are always read from the `roomAvailability/{hotelId}` Firestore
/// collection — this value is only ever used as the seed/fallback default.
typedef RoomAvailability = Map<RoomType, int>;

extension RoomAvailabilityCodec on RoomAvailability {
  Map<String, int> toJson() => map((k, v) => MapEntry(k.name, v));

  int get total => values.fold(0, (a, b) => a + b);
}

RoomAvailability roomAvailabilityFromJson(Map<String, dynamic>? json) {
  if (json == null) return defaultRoomAvailability;
  return {
    for (final type in RoomType.values)
      type: (json[type.name] as num?)?.toInt() ?? 0,
  };
}

const defaultRoomAvailability = <RoomType, int>{
  RoomType.regular: 3,
  RoomType.premium: 2,
  RoomType.luxury: 1,
};
