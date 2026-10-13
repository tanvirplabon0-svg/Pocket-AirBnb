import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/currency_formatters.dart';
import '../../data/models/hotel.dart';
import '../../providers/favorites_provider.dart';
import 'app_image.dart';

class PropertyCard extends ConsumerWidget {
  const PropertyCard({
    super.key,
    required this.hotel,
    this.onTap,
  });

  final Hotel hotel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(hotel.id);
    final formatter = ref.watch(currencyFormatterProvider);

    return Semantics(
      label: '${hotel.name} in ${hotel.city}, '
          '${formatter.format(hotel.pricePerNight, withNight: true)}, '
          'rated ${hotel.rating}',
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: _HotelImage(url: hotel.primaryImage),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      tooltip: isFavorite
                          ? 'Remove from wishlist'
                          : 'Add to wishlist',
                      onPressed: () =>
                          ref.read(favoritesProvider.notifier).toggle(hotel.id),
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isFavorite ? theme.colorScheme.error : null,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hotel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (hotel.rating > 0) ...[
                          Icon(Icons.star,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 2),
                          Text(
                            hotel.rating.toStringAsFixed(1),
                            style: theme.textTheme.labelLarge,
                          ),
                        ] else
                          Text(
                            'New',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${hotel.district}, ${hotel.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: hotel.amenities
                          .take(3)
                          .map(
                            (a) => Chip(
                              label: Text(a.replaceAll('_', ' ')),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatter.format(hotel.pricePerNight, withNight: true),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    return AppImage(url: url, memCacheWidth: 400, memCacheHeight: 250);
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.image_not_supported_outlined,
              color: scheme.onSurfaceVariant),
    );
  }
}
