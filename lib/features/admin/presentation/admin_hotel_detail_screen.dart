import 'package:flutter/material.dart';

// PLACEHOLDER - replaced by the real screen in a later step.
class AdminHotelDetailScreen extends StatelessWidget {
  const AdminHotelDetailScreen({super.key, required this.hotelId, required this.onBack});
  final String hotelId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Hotel Detail')),
      body: const Center(child: Text('This is the Admin Hotel Detail page.')),
    );
  }
}
