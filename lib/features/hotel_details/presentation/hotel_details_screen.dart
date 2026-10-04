import 'package:flutter/material.dart';

// PLACEHOLDER - replaced by the real screen in a later step.
class HotelDetailsScreen extends StatelessWidget {
  const HotelDetailsScreen({super.key, required this.hotelId});
  final String hotelId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hotel Details')),
      body: const Center(child: Text('This is the Hotel Details page.')),
    );
  }
}
