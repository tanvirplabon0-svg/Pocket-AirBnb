import 'room_availability.dart';

enum HotelSource { rapidApi, hostListing }

class Hotel {
  const Hotel({
    required this.id,
    required this.name,
    required this.city,
    this.district,
    this.address,
    required this.pricePerNight,
    this.currency = 'BDT',
    required this.rating,
    this.reviewCount = 0,
    this.lat,
    this.lng,
    required this.amenities,
    required this.images,
    this.description = '',
    this.category,
    this.availabilityStatus = 'available',
    this.source = HotelSource.rapidApi,
    this.hostUid,
    this.roomAvailability = defaultRoomAvailability,
  });

  final String id;
  final String name;
  final String city;
  final String? district;
  final String? address;
  final int pricePerNight;
  final String currency;
  final double rating;
  final int reviewCount;
  final double? lat;
  final double? lng;
  final List<String> amenities;
  final List<String> images;
  final String description;
  final String? category;
  final String availabilityStatus;
  final HotelSource source;
  final String? hostUid;
  final RoomAvailability roomAvailability;

  String get primaryImage => images.isNotEmpty ? images.first : '';
  String get location => district != null ? '$district, $city' : city;
  bool get hasCoords => lat != null && lng != null;
  bool get isHostListing => source == HotelSource.hostListing;

  factory Hotel.fromJson(Map<String, dynamic> json) {
    List<dynamic> rawImages = [];
    if (json['image_url'] != null) { rawImages.add(json['image_url']); }
    if (json['images'] is List) {
      rawImages.addAll(json['images']);
    } else if (json['image_urls'] is List) {
      rawImages.addAll(json['image_urls']);
    }

    return Hotel(
      id: (json['id'] ?? '').toString(),
      name: (json['hotel_name'] ?? json['name'] ?? 'Unknown').toString(),
      city: (json['city'] ?? '').toString(),
      district: json['district']?.toString(),
      address: (json['full_address'] ?? json['address'])?.toString(),
      pricePerNight: _toInt(
        json['nightly_price'] ?? json['pricePerNight'] ?? json['sample_nightly_price_bdt'],
      ),
      currency: (json['currency_or_note'] ?? json['currency'] ?? 'BDT').toString(),
      rating: _toDouble(json['rating'] ?? 4.5),
      reviewCount: _toInt(json['reviewCount'] ?? 120),
      lat: json['latitude'] != null ? _toDouble(json['latitude']) : (json['lat'] != null ? _toDouble(json['lat']) : null),
      lng: json['longitude'] != null ? _toDouble(json['longitude']) : (json['lng'] != null ? _toDouble(json['lng']) : null),
      amenities: _toStringList(json['amenities']),
      images: _toStringList(rawImages),
      description: (json['description'] ?? '').toString(),
      category: json['category']?.toString(),
      availabilityStatus: (json['availability'] is Map)
          ? ((json['availability'] as Map)['status'] ?? 'available').toString()
          : 'available',
      roomAvailability: roomAvailabilityFromJson(
        json['roomAvailability'] as Map<String, dynamic>?,
      ),
    );
  }

  factory Hotel.fromBookingJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['max_photo_url'] != null) {
      parsedImages.add(json['max_photo_url'].toString());
    } else if (json['main_photo_url'] != null) {
      parsedImages.add(json['main_photo_url'].toString());
    }

    final nightlyPrice = _toInt(json['min_total_price'] ?? 0);
    final curr = json['currencycode'] ?? 'USD';
    final rawReview = json['review_score'] ?? json['reviewScore'];
    final reviewScore = rawReview != null ? _toDouble(rawReview) : 0.0;

    return Hotel(
      id: (json['hotel_id'] ?? json['id'] ?? '').toString(),
      name: (json['hotel_name'] ?? json['name'] ?? 'Unknown').toString(),
      city: (json['city_trans'] ?? json['city'] ?? 'Dhaka').toString(),
      district: json['district']?.toString(),
      address: (json['address'] ?? json['address_trans'] ?? '').toString(),
      pricePerNight: nightlyPrice,
      currency: curr.toString(),
      rating: reviewScore,
      reviewCount: _toInt(json['review_nr'] ?? 0),
      lat: json['latitude'] != null ? _toDouble(json['latitude']) : null,
      lng: json['longitude'] != null ? _toDouble(json['longitude']) : null,
      amenities: const ['wifi'], 
      images: parsedImages.isNotEmpty ? parsedImages : ['https://via.placeholder.com/600x400'],
      description: '',
      category: 'budget',
      availabilityStatus: 'available',
    );
  }

  /// Adapts a host-created Property into the shape every
  /// guest-facing screen already knows how to render.
  factory Hotel.fromProperty(dynamic property) {
    return Hotel(
      id: property.id as String,
      name: property.name as String,
      city: property.city as String,
      address: property.address as String?,
      pricePerNight: property.pricePerNight as int,
      currency: property.currency as String,
      rating: 0,
      reviewCount: 0,
      lat: property.lat as double?,
      lng: property.lng as double?,
      amenities: List<String>.from(property.amenities as List),
      images: List<String>.from(property.images as List),
      description: property.description as String,
      category: 'hosted',
      availabilityStatus:
          (property.status as String) == 'active' ? 'available' : 'unavailable',
      source: HotelSource.hostListing,
      hostUid: property.hostUid as String,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static List<String> _toStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }
}
