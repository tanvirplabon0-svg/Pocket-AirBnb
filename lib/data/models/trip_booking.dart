import 'package:cloud_firestore/cloud_firestore.dart';

import 'room_type.dart';

enum TripStatus { upcoming, active, completed, cancelled }

/// Whether the guest paid the full stay online, or only a 10% deposit to
/// reserve the room and will pay the rest in cash at the property.
enum PaymentType { full, reserved }

enum PaymentMethod { bkash, nagad, rocket, upay, visa, mastercard }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.bkash => 'bKash',
        PaymentMethod.nagad => 'Nagad',
        PaymentMethod.rocket => 'Rocket',
        PaymentMethod.upay => 'Upay',
        PaymentMethod.visa => 'Visa',
        PaymentMethod.mastercard => 'Mastercard',
      };
}

/// Result of a completed payment step — the amount charged now, the amount
/// still owed (cash on arrival for a reserved booking), and how it was paid.
class PaymentResult {
  const PaymentResult({
    required this.paymentType,
    required this.paymentMethod,
    required this.amountPaid,
    required this.amountDue,
  });

  final PaymentType paymentType;
  final PaymentMethod paymentMethod;
  final int amountPaid;
  final int amountDue;
}

class TripBooking {
  const TripBooking({
    required this.id,
    required this.hotelId,
    required this.hotelName,
    required this.hotelCity,
    required this.hotelImage,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.rooms,
    required this.totalPrice,
    required this.status,
    this.confirmationCode = '',
    this.rating,
    this.review,
    this.paymentType = PaymentType.full,
    this.paymentMethod,
    this.amountPaid = 0,
    this.amountDue = 0,
    this.roomType = RoomType.regular,
    this.addOnIds = const [],
  });

  final String id;
  final String hotelId;
  final String hotelName;
  final String hotelCity;
  final String hotelImage;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int rooms;
  final int totalPrice;
  final TripStatus status;
  final String confirmationCode;
  final double? rating;
  final String? review;

  /// Full online payment, or a 10% deposit with cash-on-arrival for the rest.
  final PaymentType paymentType;
  final PaymentMethod? paymentMethod;
  final int amountPaid;
  final int amountDue;

  final RoomType roomType;
  final List<String> addOnIds; // AddOn.id values

  int get nights => checkOut.difference(checkIn).inDays;

  /// Status computed from actual dates — used for display and filtering.
  /// Stored status is the source of truth for cancellation;
  /// for active/completed we derive from the dates in real time.
  TripStatus get effectiveStatus {
    if (status == TripStatus.cancelled) return TripStatus.cancelled;
    final now = DateTime.now();
    if (now.isAfter(checkOut)) return TripStatus.completed;
    if (!now.isBefore(checkIn)) return TripStatus.active;
    return TripStatus.upcoming;
  }

  TripBooking copyWith({
    TripStatus? status,
    double? rating,
    String? review,
  }) =>
      TripBooking(
        id: id,
        hotelId: hotelId,
        hotelName: hotelName,
        hotelCity: hotelCity,
        hotelImage: hotelImage,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
        rooms: rooms,
        totalPrice: totalPrice,
        status: status ?? this.status,
        confirmationCode: confirmationCode,
        rating: rating ?? this.rating,
        review: review ?? this.review,
        paymentType: paymentType,
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        amountDue: amountDue,
        roomType: roomType,
        addOnIds: addOnIds,
      );

  /// Accepts either ISO-8601 strings (local JSON) or Firestore [Timestamp]s
  /// for the date fields, so one model serves both persistence layers.
  factory TripBooking.fromJson(Map<String, dynamic> data) {
    return TripBooking(
      id: data['id'] as String? ?? '',
      hotelId: data['hotelId'] as String? ?? '',
      hotelName: data['hotelName'] as String? ?? '',
      hotelCity: data['hotelCity'] as String? ?? '',
      hotelImage: data['hotelImage'] as String? ?? '',
      checkIn: _parseDate(data['checkIn']),
      checkOut: _parseDate(data['checkOut']),
      guests: (data['guests'] as num?)?.toInt() ?? 1,
      rooms: (data['rooms'] as num?)?.toInt() ?? 1,
      totalPrice: (data['totalPrice'] as num?)?.toInt() ?? 0,
      status: TripStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String? ?? 'upcoming'),
        orElse: () => TripStatus.upcoming,
      ),
      confirmationCode: data['confirmationCode'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble(),
      review: data['review'] as String?,
      paymentType: PaymentType.values.firstWhere(
        (t) => t.name == (data['paymentType'] as String? ?? 'full'),
        orElse: () => PaymentType.full,
      ),
      paymentMethod: data['paymentMethod'] == null
          ? null
          : PaymentMethod.values.firstWhere(
              (m) => m.name == data['paymentMethod'],
              orElse: () => PaymentMethod.bkash,
            ),
      amountPaid: (data['amountPaid'] as num?)?.toInt() ?? 0,
      amountDue: (data['amountDue'] as num?)?.toInt() ?? 0,
      roomType: RoomType.values.firstWhere(
        (t) => t.name == (data['roomType'] as String? ?? 'regular'),
        orElse: () => RoomType.regular,
      ),
      addOnIds: (data['addOnIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hotelId': hotelId,
        'hotelName': hotelName,
        'hotelCity': hotelCity,
        'hotelImage': hotelImage,
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
        'guests': guests,
        'rooms': rooms,
        'totalPrice': totalPrice,
        'status': status.name,
        'confirmationCode': confirmationCode,
        if (rating != null) 'rating': rating,
        if (review != null) 'review': review,
        'paymentType': paymentType.name,
        if (paymentMethod != null) 'paymentMethod': paymentMethod!.name,
        'amountPaid': amountPaid,
        'amountDue': amountDue,
        'roomType': roomType.name,
        'addOnIds': addOnIds,
      };

  /// Same shape as [toJson] but with a Firestore server timestamp so
  /// query ordering by check-in date works as a real Timestamp field.
  Map<String, dynamic> toFirestore() => {
        'hotelId': hotelId,
        'hotelName': hotelName,
        'hotelCity': hotelCity,
        'hotelImage': hotelImage,
        'checkIn': Timestamp.fromDate(checkIn),
        'checkOut': Timestamp.fromDate(checkOut),
        'guests': guests,
        'rooms': rooms,
        'totalPrice': totalPrice,
        'status': status.name,
        'confirmationCode': confirmationCode,
        if (rating != null) 'rating': rating,
        if (review != null) 'review': review,
        'paymentType': paymentType.name,
        if (paymentMethod != null) 'paymentMethod': paymentMethod!.name,
        'amountPaid': amountPaid,
        'amountDue': amountDue,
        'roomType': roomType.name,
        'addOnIds': addOnIds,
      };
}
