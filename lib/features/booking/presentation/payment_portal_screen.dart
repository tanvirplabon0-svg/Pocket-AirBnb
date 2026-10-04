import 'package:flutter/material.dart';

// PLACEHOLDER - replaced by the real screen in a later step.
class PaymentPortalScreen extends StatelessWidget {
  const PaymentPortalScreen({super.key, required this.totalPrice});
  final int totalPrice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Portal')),
      body: const Center(child: Text('This is the Payment Portal page.')),
    );
  }
}
