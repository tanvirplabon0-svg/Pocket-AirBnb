import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/hotel.dart';

/// Loads the bundled hotel catalog from assets.
/// This is the app's only hotel data source until a real backend exists.
class HotelRepository {
  const HotelRepository();

  static const _fixturePath = 'assets/fixtures/hotels_bd.json';

  Future<List<Hotel>> loadHotels() async {
    final raw = await rootBundle.loadString(_fixturePath);
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Hotel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
