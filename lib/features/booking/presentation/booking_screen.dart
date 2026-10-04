import 'package:flutter/material.dart';
import '../../../data/models/hotel.dart';
// PLACEHOLDER - replaced by the real screen in a later step.
class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key, required this.hotel});
  final Hotel hotel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: const Center(child: Text('This is the Booking page.')),
    );
  }
}
