import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/currency_formatters.dart';
import '../../data/models/hotel.dart';
import '../../providers/favorites_provider.dart';
import 'app_image.dart';
import 'hotel_detail_sheet.dart';

class HotelCard extends ConsumerWidget {
  const HotelCard({super.key, required this.hotel});

  final Hotel hotel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final formatter = ref.watch(currencyFormatterProvider);
    final isFav = favorites.contains(hotel.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showHotelDetailSheet(context, hotel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _HotelImage(url: hotel.primaryImage),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _FavButton(
                        hotelId: hotel.id, isFav: isFav),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hotel.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rating
                      _RatingPill(rating: hotel.rating),
                      // Price
                      Expanded(
                        child: Text(
                          formatter.format(hotel.pricePerNight, withNight: true),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hotel.amenities.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _AmenityChips(amenities: hotel.amenities.take(3).toList()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotelImage extends StatelessWidget {
  const _HotelImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return AppImage(url: url, memCacheWidth: 400);
  }
}

class _FavButton extends ConsumerWidget {
  const _FavButton({required this.hotelId, required this.isFav});

  final String hotelId;
  final bool isFav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => ref.read(favoritesProvider.notifier).toggle(hotelId),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkCard : Colors.white).withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: isFav ? AppColors.accentRed : (isDark ? AppColors.darkTextPrimary : AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: rating > 0
            ? [
                const Icon(Icons.star, size: 11, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]
            : const [
                Text(
                  'New',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
      ),
    );
  }
}

class _AmenityChips extends StatelessWidget {
  const _AmenityChips({required this.amenities});

  final List<String> amenities;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: amenities.map((a) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.warmSand,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Text(
            a.replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }
}
