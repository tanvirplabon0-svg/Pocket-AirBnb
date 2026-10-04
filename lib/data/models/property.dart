import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  const Property({
    required this.id,
    required this.hostUid,
    required this.name,
    this.description = '',
    required this.city,
    this.address,
    required this.pricePerNight,
    this.currency = 'BDT',
    this.lat,
    this.lng,
    this.amenities = const [],
    this.images = const [],
    this.blockedDates = const [],
    required this.createdAt,
    this.status = 'active',
    this.bookingCount = 0,
  });

  final String id;
  final String hostUid;
  final String name;
  final String description;
  final String city;
  final String? address;
  final int pricePerNight;
  final String currency;
  final double? lat;
  final double? lng;
  final List<String> amenities;
  final List<String> images;
  final List<String> blockedDates;
  final DateTime createdAt;
  final String status;
  final int bookingCount;

  String get primaryImage => images.isNotEmpty ? images.first : '';

  Property copyWith({
    String? name,
    String? description,
    String? city,
    String? address,
    int? pricePerNight,
    String? currency,
    double? lat,
    double? lng,
    List<String>? amenities,
    List<String>? images,
    List<String>? blockedDates,
    String? status,
  }) => Property(
    id: id,
    hostUid: hostUid,
    name: name ?? this.name,
    description: description ?? this.description,
    city: city ?? this.city,
    address: address ?? this.address,
    pricePerNight: pricePerNight ?? this.pricePerNight,
    currency: currency ?? this.currency,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    amenities: amenities ?? this.amenities,
    images: images ?? this.images,
    blockedDates: blockedDates ?? this.blockedDates,
    createdAt: createdAt,
    status: status ?? this.status,
  );

  factory Property.fromJson(Map<String, dynamic> data) {
    return Property(
      id: (data['id'] ?? '').toString(),
      hostUid: (data['hostUid'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      address: data['address']?.toString(),
      pricePerNight: (data['pricePerNight'] as num?)?.toInt() ?? 0,
      currency: (data['currency'] ?? 'BDT').toString(),
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      amenities: List<String>.from(data['amenities'] as List? ?? []),
      images: List<String>.from(data['images'] as List? ?? []),
      blockedDates: List<String>.from(data['blockedDates'] as List? ?? []),
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
      status: (data['status'] ?? 'active').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hostUid': hostUid,
    'name': name,
    'description': description,
    'city': city,
    'address': address,
    'pricePerNight': pricePerNight,
    'currency': currency,
    'lat': lat,
    'lng': lng,
    'amenities': amenities,
    'images': images,
    'blockedDates': blockedDates,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
  };

  factory Property.fromFirestore(Map<String, dynamic> data, String id) {
    final rawCreatedAt = data['createdAt'];
    return Property(
      id: id,
      hostUid: (data['hostUid'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      address: data['address']?.toString(),
      pricePerNight: (data['pricePerNight'] as num?)?.toInt() ?? 0,
      currency: (data['currency'] ?? 'BDT').toString(),
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      amenities: List<String>.from(data['amenities'] as List? ?? []),
      images: List<String>.from(data['images'] as List? ?? []),
      blockedDates: List<String>.from(data['blockedDates'] as List? ?? []),
      createdAt: rawCreatedAt is Timestamp
          ? rawCreatedAt.toDate()
          : DateTime.now(),
      status: (data['status'] ?? 'active').toString(),
      bookingCount: (data['bookingCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'hostUid': hostUid,
    'name': name,
    'description': description,
    'city': city,
    'address': address,
    'pricePerNight': pricePerNight,
    'currency': currency,
    'lat': lat,
    'lng': lng,
    'amenities': amenities,
    'images': images,
    'blockedDates': blockedDates,
    'createdAt': FieldValue.serverTimestamp(),
    'status': status,
  };
}
