import '../../data/models/add_on.dart';

typedef BookingTotals = ({
  int roomRate,
  int subtotal,
  int serviceFee,
  int tax,
  int total,
});

/// Pure price math shared by the booking screen: room rate (after the
/// room-type multiplier) × nights, plus add-ons, plus service fee and tax
/// on that subtotal.
BookingTotals computeBookingTotals({
  required int pricePerNight,
  required double priceMultiplier,
  required int nights,
  required List<AddOn> addOns,
  double serviceFeeRate = 0.07,
  double taxRate = 0.05,
}) {
  final roomRate = (pricePerNight * priceMultiplier).round();
  final roomSubtotal = roomRate * nights;
  final addOnsTotal = addOns.fold<int>(0, (sum, a) => sum + a.price);
  final subtotal = roomSubtotal + addOnsTotal;
  final serviceFee = (subtotal * serviceFeeRate).round();
  final tax = (subtotal * taxRate).round();
  return (
    roomRate: roomRate,
    subtotal: subtotal,
    serviceFee: serviceFee,
    tax: tax,
    total: subtotal + serviceFee + tax,
  );
}
