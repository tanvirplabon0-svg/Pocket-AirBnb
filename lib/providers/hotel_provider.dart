import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/hotel.dart';
import '../data/models/room_availability.dart';
import '../data/repositories/hotel_repository.dart';
import '../data/services/firestore_service.dart';

// ─── Repository provider ─────────────────────────────────────────────────────

final hotelRepositoryProvider = Provider<HotelRepository>((ref) {
  return const HotelRepository();
});

// ─── Raw hotel list ──────────────────────────────────────────────────────────

/// Bundled hotel catalog merged with every active host-created listing
/// (from any host, not just the current user), so "Become a Host"
/// properties show up in every guest's Explore/Search/Map.
/// When unauthenticated the Firestore query is skipped (rules require auth)
/// so the bundled catalog is returned alone — no PERMISSION_DENIED noise.
final hotelsProvider = FutureProvider<List<Hotel>>((ref) async {
  final catalog = await ref.read(hotelRepositoryProvider).loadHotels();
  // Only hit Firestore when a user is signed in — the security rules
  // require request.auth != null on /properties reads.
  if (FirebaseAuth.instance.currentUser == null) return catalog;
  final properties = await FirestoreService.instance.getActiveProperties();
  final hostListings = properties.map(Hotel.fromProperty).toList();
  return [...hostListings, ...catalog];
});

// ─── Live room availability ────────────────────────────────────────────────

/// One-shot live read of a hotel's real room-availability counts from
/// `roomAvailability/{hotelId}` — falls back to that hotel's static seed
/// value if it's never been booked yet (no counter doc exists).
///
/// Keyed by hotel id (a String), not a [Hotel] instance — [Hotel] has no
/// value equality, so keying by instance would silently create a separate
/// cache entry (and defeat invalidation) whenever a different in-memory
/// Hotel object for the same id is passed in, e.g. from a different screen.
final liveAvailabilityProvider =
    FutureProvider.family<RoomAvailability, String>((ref, hotelId) async {
  final live = await FirestoreService.instance.getAvailability(hotelId);
  if (live != null) return live;
  final hotels = await ref.read(hotelsProvider.future);
  final match = hotels.where((h) => h.id == hotelId);
  return match.isEmpty ? defaultRoomAvailability : match.first.roomAvailability;
});

// ─── Filter state ─────────────────────────────────────────────────────────────

final searchQueryProvider     = StateProvider<String>((ref) => '');
final selectedCityProvider    = StateProvider<String?>((ref) => null);
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final minRatingProvider       = StateProvider<double>((ref) => 0.0);
final priceRangeProvider      = StateProvider<RangeValues>(
  (ref) => const RangeValues(0, 30000),
);

enum SortOption { recommended, priceLowHigh, priceHighLow, ratingHighLow }

final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.recommended);

// ─── Filtered + sorted hotels ─────────────────────────────────────────────────

final filteredHotelsProvider = Provider<AsyncValue<List<Hotel>>>((ref) {
  final hotelsAsync = ref.watch(hotelsProvider);
  return hotelsAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (hotels) {
      final query    = ref.watch(searchQueryProvider).trim().toLowerCase();
      final city     = ref.watch(selectedCityProvider);
      final category = ref.watch(selectedCategoryProvider);
      final minRating = ref.watch(minRatingProvider);
      final priceRange = ref.watch(priceRangeProvider);
      final sort      = ref.watch(sortOptionProvider);

      var result = hotels.where((h) {
        if (query.isNotEmpty &&
            !h.name.toLowerCase().contains(query) &&
            !h.city.toLowerCase().contains(query) &&
            !(h.district?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
        if (city != null && h.city != city) return false;
        if (h.rating < minRating) return false;
        if (category?.toLowerCase() != 'budget') {
          if (h.pricePerNight < priceRange.start ||
              h.pricePerNight > priceRange.end) {
            return false;
          }
        }
        if (category != null && !_matchesCategory(h, category)) { return false; }
        return true;
      }).toList();

      switch (sort) {
        case SortOption.priceLowHigh:
          result.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
          break;
        case SortOption.priceHighLow:
          result.sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));
          break;
        case SortOption.ratingHighLow:
          result.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case SortOption.recommended:
          result.sort((a, b) => b.rating.compareTo(a.rating));
          break;
      }
      return AsyncData(result);
    },
  );
});

bool _matchesCategory(Hotel h, String cat) {
  switch (cat.toLowerCase()) {
    case 'beach':
      return h.category == 'beach' ||
          h.city == "Cox's Bazar" ||
          h.city.toLowerCase().contains('cox') ||
          h.name.toLowerCase().contains('beach') ||
          h.description.toLowerCase().contains('beach');
    case 'luxury':
      return h.pricePerNight >= 15000 || h.category == 'luxury';
    case 'budget':
      return true;
    case 'business':
      return (h.city == 'Dhaka' && h.amenities.contains('wifi')) ||
          h.category == 'business';
    case 'family':
      return h.amenities.contains('restaurant') &&
          h.amenities.contains('wifi');
    case 'airport':
      return h.amenities.contains('airport_shuttle');
    case 'resort':
      return h.name.toLowerCase().contains('resort') ||
          h.amenities.contains('pool') ||
          h.category == 'resort';
    case 'boutique':
      return (h.rating >= 8.5 &&
          h.pricePerNight >= 5000 &&
          h.pricePerNight < 15000) ||
          h.category == 'boutique';
    default:
      return true;
  }
}

// ─── Available filter options ─────────────────────────────────────────────────

final availableCitiesProvider = Provider<List<String>>((ref) {
  final hotels = ref.watch(hotelsProvider).valueOrNull ?? [];
  return ({...hotels.map((h) => h.city)}.toList()..sort());
});

final availableAmenitiesProvider = Provider<List<String>>((ref) {
  final hotels = ref.watch(hotelsProvider).valueOrNull ?? [];
  final all = <String>{};
  for (final h in hotels) { all.addAll(h.amenities); }
  return (all.toList()..sort());
});

// ─── Clear filters ────────────────────────────────────────────────────────────

void clearAllFilters(WidgetRef ref) {
  ref.read(searchQueryProvider.notifier).state = '';
  ref.read(selectedCityProvider.notifier).state = null;
  ref.read(selectedCategoryProvider.notifier).state = null;
  ref.read(minRatingProvider.notifier).state = 0.0;
  ref.read(priceRangeProvider.notifier).state = const RangeValues(0, 30000);
  ref.read(sortOptionProvider.notifier).state = SortOption.recommended;
}
