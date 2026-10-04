import 'package:flutter/material.dart';

// PLACEHOLDER - replaced by the real screen in a later step.
class AvailabilityCalendarScreen extends StatelessWidget {
  const AvailabilityCalendarScreen({super.key, required this.propertyId});
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Availability Calendar')),
      body: const Center(child: Text('This is the Availability Calendar page.')),
    );
  }
}
