import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../data/models/hotel.dart';
import '../../../data/models/room_type.dart';
import '../../../providers/hotel_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../shared/widgets/app_image.dart';

class HotelDetailsScreen extends ConsumerWidget {
  const HotelDetailsScreen({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotelsAsync = ref.watch(hotelsProvider);

    return hotelsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
      data: (hotels) {
        final hotel = hotels.firstWhere(
          (h) => h.id == hotelId,
          orElse: () => hotels.first,
        );
        return _HotelDetailsView(hotel: hotel);
      },
    );
  }
}

class _HotelDetailsView extends ConsumerStatefulWidget {
  const _HotelDetailsView({required this.hotel});

  final Hotel hotel;

  @override
  ConsumerState<_HotelDetailsView> createState() => _HotelDetailsViewState();
}

class _HotelDetailsViewState extends ConsumerState<_HotelDetailsView> {
  int _imageIndex = 0;
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final isFav = ref.watch(favoritesProvider).contains(hotel.id);
    final formatter = ref.watch(currencyFormatterProvider);
    final allImages = hotel.images;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── Image carousel ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: isDark ? AppColors.darkCard : Colors.white.withValues(alpha: 0.85),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, size: 18, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkCard : Colors.white.withValues(alpha: 0.85),
                  child: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFav ? AppColors.accentRed : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                    ),
                    onPressed: () =>
                        ref.read(favoritesProvider.notifier).toggle(hotel.id),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: allImages.isEmpty
                  ? Container(
                      color: isDark ? AppColors.darkCard : AppColors.warmSand,
                      child: Icon(Icons.hotel,
                          size: 80, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: _pageCtrl,
                          itemCount: allImages.length,
                          onPageChanged: (i) =>
                              setState(() => _imageIndex = i),
                          itemBuilder: (_, i) => AppImage(
                            url: allImages[i],
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (allImages.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                allImages.length > 15 ? 15 : allImages.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: i == _imageIndex ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i == _imageIndex
                                        ? Colors.white
                                        : Colors.white54,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          // ─── Content ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    hotel.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        hotel.address ?? hotel.location,
                        style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Rating & reviews
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              hotel.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${hotel.reviewCount} reviews',
                        style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: isDark ? AppColors.darkBorder : AppColors.border),
                  const SizedBox(height: 16),
                  // Amenities
                  if (hotel.amenities.isNotEmpty) ...[
                    Text(
                      'Amenities',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hotel.amenities.map((a) {
                        return Chip(
                          label: Text(a.replaceAll('_', ' ')),
                          avatar: Icon(
                              _amenityIcon(a), size: 16, color: AppColors.primary),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.07),
                          side: const BorderSide(
                              color: AppColors.primary, width: 0.5),
                          labelStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: isDark ? AppColors.darkBorder : AppColors.border),
                    const SizedBox(height: 16),
                  ],
                  // Availability
                  Text(
                    'Availability',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 10),
                  Consumer(
                    builder: (context, ref, _) {
                      final availAsync =
                          ref.watch(liveAvailabilityProvider(hotel.id));
                      return availAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (avail) => Column(
                          children: [
                            for (final type in RoomType.values)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(type.label,
                                        style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface)),
                                    Text(
                                      (avail[type] ?? 0) > 0
                                          ? '${avail[type]} available'
                                          : 'Sold out',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: (avail[type] ?? 0) > 0
                                            ? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)
                                            : AppColors.accentRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Divider(color: isDark ? AppColors.darkBorder : AppColors.border),
                  const SizedBox(height: 16),
                  // Description
                  if (hotel.description.isNotEmpty) ...[
                    Text(
                      'About',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hotel.description,
                      style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          height: 1.6,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: isDark ? AppColors.darkBorder : AppColors.border),
                    const SizedBox(height: 16),
                  ],
                  // Location
                  if (hotel.hasCoords) ...[
                    Text(
                      'Location',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.location_on,
                              size: 32, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text(
                            hotel.address ?? hotel.location,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${hotel.lat!.toStringAsFixed(5)}, '
                            'Lng: ${hotel.lng!.toStringAsFixed(5)}',
                            style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => context.go(AppRoutes.map),
                            icon: const Icon(Icons.map_outlined, size: 16),
                            label: const Text('View on Map'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 38),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Extra space for bottom bar
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      // ─── Bottom sticky bar ────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatter.format(hotel.pricePerNight),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'per night',
                  style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: hotel.availabilityStatus == 'available'
                    ? () => context.push(
                        '${AppRoutes.booking}/${hotel.id}',
                        extra: hotel,
                      )
                    : null,
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  hotel.availabilityStatus == 'available'
                      ? 'Reserve Now'
                      : 'Unavailable',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _amenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi': return Icons.wifi;
      case 'pool': return Icons.pool;
      case 'spa': return Icons.spa_outlined;
      case 'gym': return Icons.fitness_center;
      case 'restaurant': return Icons.restaurant_outlined;
      case 'parking': return Icons.local_parking;
      case 'airport_shuttle': return Icons.airport_shuttle_outlined;
      case 'bar': return Icons.local_bar_outlined;
      case 'ac': return Icons.ac_unit;
      case 'room_service': return Icons.room_service_outlined;
      case 'tv': return Icons.tv_outlined;
      default: return Icons.check_circle_outline;
    }
  }
}
