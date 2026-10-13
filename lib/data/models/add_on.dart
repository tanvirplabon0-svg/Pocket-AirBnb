/// A paid extra a guest can add to a booking (breakfast, airport pickup,
/// etc.). Fixed catalog — `id` is what gets persisted in Firestore/JSON,
/// never the display label, so relabeling later never breaks stored data.
class AddOn {
  const AddOn({required this.id, required this.label, required this.price});

  final String id;
  final String label;
  final int price; // BDT, fixed

  static const List<AddOn> catalog = [
    AddOn(id: 'breakfast', label: 'Breakfast', price: 500),
    AddOn(id: 'airport_pickup', label: 'Airport Pickup', price: 1500),
    AddOn(id: 'late_checkout', label: 'Late Checkout', price: 800),
    AddOn(id: 'extra_bed', label: 'Extra Bed', price: 1200),
  ];

  static AddOn byId(String id) =>
      catalog.firstWhere((a) => a.id == id, orElse: () => catalog.first);
}
