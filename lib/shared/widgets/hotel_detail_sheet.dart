import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/currency_formatters.dart';
import '../../data/models/hotel.dart';
import '../../providers/favorites_provider.dart';
import 'app_image.dart';

/// Opens the Airbnb-style hotel detail bottom sheet.
void showHotelDetailSheet(BuildContext context, Hotel hotel) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.96,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      snap: true,
      snapSizes: const [0.96, 1.0],
      builder: (ctx, scrollController) => _HotelDetailSheet(
        hotel: hotel,
        scrollController: scrollController,
      ),
    ),
  );
}

class _HotelDetailSheet extends ConsumerStatefulWidget {
  const _HotelDetailSheet({
    required this.hotel,
    required this.scrollController,
  });

  final Hotel hotel;
  final ScrollController scrollController;

  @override
  ConsumerState<_HotelDetailSheet> createState() => _HotelDetailSheetState();
}

class _HotelDetailSheetState extends ConsumerState<_HotelDetailSheet> {
  int _imageIndex = 0;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final isFav = ref.watch(favoritesProvider).contains(hotel.id);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              // ── Drag handle ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── Image gallery ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _ImageGallery(
                  hotel: hotel,
                  imageIndex: _imageIndex,
                  pageCtrl: _pageCtrl,
                  isFav: isFav,
                  onPageChanged: (i) => setState(() => _imageIndex = i),
                  onFavToggle: () =>
                      ref.read(favoritesProvider.notifier).toggle(hotel.id),
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),

              // ── Hotel info ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomPad + 88),
                  child: _HotelInfo(hotel: hotel),
                ),
              ),
            ],
          ),

          // ── Sticky bottom bar ────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BookingBar(hotel: hotel, bottomPad: bottomPad),
          ),
        ],
      ),
    );
  }
}

// ─── Image gallery ────────────────────────────────────────────────────────────

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({
    required this.hotel,
    required this.imageIndex,
    required this.pageCtrl,
    required this.isFav,
    required this.onPageChanged,
    required this.onFavToggle,
    required this.onClose,
  });

  final Hotel hotel;
  final int imageIndex;
  final PageController pageCtrl;
  final bool isFav;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onFavToggle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (hotel.images.isEmpty) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          color: AppColors.warmSand,
          child: const Icon(Icons.hotel, size: 64, color: AppColors.textSecondary),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Images
          PageView.builder(
            controller: pageCtrl,
            itemCount: hotel.images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, i) => AppImage(
              url: hotel.images[i],
              fit: BoxFit.cover,
            ),
          ),

          // Close button (top-left)
          Positioned(
            top: 12,
            left: 12,
            child: _CircleIconButton(
              icon: Icons.close,
              onPressed: onClose,
              tooltip: 'Close',
            ),
          ),

          // Favorite button (top-right)
          Positioned(
            top: 12,
            right: 12,
            child: _CircleIconButton(
              icon: isFav ? Icons.favorite : Icons.favorite_border,
              iconColor: isFav ? AppColors.accentRed : null,
              onPressed: onFavToggle,
              tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
            ),
          ),

          // Dot indicators (bottom)
          if (hotel.images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(hotel.images.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == imageIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == imageIndex ? Colors.white : Colors.white60,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

          // Photo count badge
          Positioned(
            bottom: 12,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${imageIndex + 1} / ${hotel.images.length}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hotel info content ───────────────────────────────────────────────────────

class _HotelInfo extends StatefulWidget {
  const _HotelInfo({required this.hotel});
  final Hotel hotel;

  @override
  State<_HotelInfo> createState() => _HotelInfoState();
}

class _HotelInfoState extends State<_HotelInfo> {
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Name + category badge ─────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                hotel.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  height: 1.25,
                ),
              ),
            ),
            if (hotel.category != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Text(
                  hotel.category!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),

        // ── Location ──────────────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 15, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                hotel.address ?? hotel.location,
                style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Rating + reviews + availability ───────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        fontSize: 13),
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
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: hotel.availabilityStatus == 'available'
                    ? (isDark ? Colors.green.shade900.withValues(alpha: 0.4) : Colors.green.shade50)
                    : (isDark ? Colors.orange.shade900.withValues(alpha: 0.4) : Colors.orange.shade50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                hotel.availabilityStatus == 'available'
                    ? 'Available'
                    : 'Limited',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hotel.availabilityStatus == 'available'
                      ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                      : (isDark ? Colors.orange.shade300 : Colors.orange.shade700),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Divider(color: isDark ? AppColors.darkBorder : AppColors.border),
        const SizedBox(height: 20),

        // ── What this place offers (amenities) ────────────────────────────
        if (hotel.amenities.isNotEmpty) ...[
          Text(
            'What this place offers',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 14),
          ...hotel.amenities.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Icon(_amenityIcon(a),
                        size: 22, color: theme.colorScheme.onSurface),
                    const SizedBox(width: 16),
                    Text(
                      a.replaceAll('_', ' ').toUpperCase().substring(0, 1) +
                          a.replaceAll('_', ' ').substring(1),
                      style: TextStyle(
                          fontSize: 14, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 6),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.border),
          const SizedBox(height: 20),
        ],

        // ── About this place ──────────────────────────────────────────────
        if (hotel.description.isNotEmpty) ...[
          Text(
            'About this place',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 10),
          Text(
            _descExpanded
                ? hotel.description
                : (hotel.description.length > 200
                    ? '${hotel.description.substring(0, 200)}...'
                    : hotel.description),
            style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.65,
                fontSize: 14),
          ),
          if (hotel.description.length > 200) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Text(
                _descExpanded ? 'Show less' : 'Show more',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.border),
          const SizedBox(height: 20),
        ],

        // ── Where you'll be ───────────────────────────────────────────────
        Text(
          "Where you'll be",
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 10),
        Text(
          hotel.address ?? hotel.location,
          style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),
        _MapPlaceholder(hotel: hotel),
      ],
    );
  }

  IconData _amenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'pool':
        return Icons.pool;
      case 'spa':
        return Icons.spa_outlined;
      case 'gym':
        return Icons.fitness_center;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'parking':
        return Icons.local_parking;
      case 'airport_shuttle':
        return Icons.airport_shuttle_outlined;
      case 'bar':
        return Icons.local_bar_outlined;
      case 'ac':
        return Icons.ac_unit;
      case 'room_service':
        return Icons.room_service_outlined;
      case 'tv':
        return Icons.tv_outlined;
      case 'laundry':
        return Icons.local_laundry_service_outlined;
      case 'conference':
        return Icons.meeting_room_outlined;
      case 'business_center':
        return Icons.business_center_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.hotel});
  final Hotel hotel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!hotel.hasCoords) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Text(
          'Location not available for this property',
          style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    final point = LatLng(hotel.lat!, hotel.lng!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: IgnorePointer(
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                        : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.stay_bd',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.hotel,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6)
                    ],
                  ),
                  child: Text(
                    hotel.address ?? hotel.location,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sticky booking bar ───────────────────────────────────────────────────────

class _BookingBar extends ConsumerWidget {
  const _BookingBar({required this.hotel, required this.bottomPad});
  final Hotel hotel;
  final double bottomPad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(currencyFormatterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomPad),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          // Price
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(hotel.pricePerNight),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '/ night',
                      style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 12, color: AppColors.primary),
                  const SizedBox(width: 2),
                  Text(
                    '${hotel.rating.toStringAsFixed(1)}  ·  ${hotel.reviewCount} reviews',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Reserve button
          Expanded(
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(
                  '${AppRoutes.booking}/${hotel.id}',
                  extra: hotel,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Reserve',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              size: 20,
              color: iconColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
        ),
      ),
    );
  }
}
