import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/hotel.dart';
import '../../../providers/hotel_provider.dart';
import '../../../providers/inbox_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/hotel_detail_sheet.dart';
import '../../../shared/widgets/property_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotelsAsync = ref.watch(hotelsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: hotelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: 'Failed to load stays.\n$e',
          onRetry: () => ref.invalidate(hotelsProvider),
        ),
        data: (hotels) => _ExploreView(
          hotels: hotels,
          unreadCount: ref.watch(unreadCountProvider),
          userInitials: ref.watch(profileProvider).initials,
        ),
      ),
    );
  }
}

// ─── Explore content ─────────────────────────────────────────────────────────

class _ExploreView extends StatelessWidget {
  const _ExploreView({
    required this.hotels,
    required this.unreadCount,
    required this.userInitials,
  });

  final List<Hotel> hotels;
  final int unreadCount;
  final String userInitials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sortedHotels = (hotels.toList()
          ..sort((a, b) => b.rating.compareTo(a.rating)));
    final radissonIdx = sortedHotels.indexWhere(
        (h) => h.name.toLowerCase().contains('radisson'));
    List<Hotel> popular;
    if (radissonIdx != -1) {
      final radisson = sortedHotels.removeAt(radissonIdx);
      popular = [radisson, ...sortedHotels].take(10).toList();
    } else {
      popular = sortedHotels.take(10).toList();
    }
    final coxsBazar = hotels.where((h) => h.city == "Cox's Bazar").toList();
    final dhaka = hotels.where((h) => h.city == 'Dhaka').toList();
    final sylhet = hotels
        .where((h) => h.city == 'Sylhet' || h.city == 'Sreemangal')
        .toList();
    final chittagong =
        hotels.where((h) => h.city == 'Chattogram').toList();

    return CustomScrollView(
      slivers: [
        // ── App Bar ──────────────────────────────────────────────────────
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 16,
          title: Row(
            children: [
              const Icon(Icons.location_on,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 4),
              Text(
                'Bangladesh',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Admin Panel',
              onPressed: () => context.push(AppRoutes.adminDashboard),
              icon: const Icon(Icons.admin_panel_settings_outlined,
                  color: AppColors.primary),
            ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.push(AppRoutes.inbox),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_none,
                      color: theme.colorScheme.onSurface),
                  if (unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.profile),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    userInitials,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
                height: 1, color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.5)),
          ),
        ),

        // ── Search bar ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: AppSearchBar(
              summary: 'Where to in Bangladesh?',
              subtitle: 'Anywhere · Any week · Add guests',
              onTap: () => context.go(AppRoutes.listings),
              onFilterTap: () => context.go(AppRoutes.listings),
            ),
          ),
        ),

        // ── Category quick-filter chips ───────────────────────────────────
        const SliverToBoxAdapter(
          child: _CategoryRow(),
        ),

        // ── Sections ──────────────────────────────────────────────────────
        _HotelSection(
            title: 'Popular in Bangladesh',
            icon: Icons.workspace_premium,
            iconColor: AppColors.primary,
            hotels: popular),
        if (dhaka.isNotEmpty)
          _HotelSection(
              title: 'Dhaka Business & Luxury',
              icon: Icons.location_city,
              iconColor: AppColors.primary,
              hotels: dhaka),
        if (coxsBazar.isNotEmpty)
          _HotelSection(
              title: 'Cox\'s Bazar Beach Stays',
              icon: Icons.beach_access,
              iconColor: AppColors.primary,
              hotels: coxsBazar),
        if (sylhet.isNotEmpty)
          _HotelSection(
              title: 'Sylhet Tea Country',
              icon: Icons.eco,
              iconColor: AppColors.primary,
              hotels: sylhet),
        if (chittagong.isNotEmpty)
          _HotelSection(
              title: 'Chattogram Port City',
              icon: Icons.sailing,
              iconColor: AppColors.primary,
              hotels: chittagong),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ─── Category filter row ──────────────────────────────────────────────────────

class _CategoryRow extends ConsumerStatefulWidget {
  const _CategoryRow();

  @override
  ConsumerState<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends ConsumerState<_CategoryRow> {
  String? _selected;

  static const _cats = [
    ('Beach', Icons.beach_access_outlined),
    ('Luxury', Icons.diamond_outlined),
    ('Budget', Icons.savings_outlined),
    ('Business', Icons.business_center_outlined),
    ('Family', Icons.family_restroom_outlined),
    ('Resort', Icons.villa_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, icon) = _cats[i];
          final isSelected = _selected == label;
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return FilterChip(
            selected: isSelected,
            avatar: Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.primary),
            label: Text(label),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: theme.cardColor,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.border),
            ),
            checkmarkColor: Colors.white,
            showCheckmark: false,
            onSelected: (_) {
              setState(() => _selected = isSelected ? null : label);
              // Apply category filter and navigate to listings
              if (!isSelected) {
                ref.read(selectedCategoryProvider.notifier).state = label;
                if (label == 'Budget') {
                  ref.read(priceRangeProvider.notifier).state = const RangeValues(0, 30000);
                  ref.read(sortOptionProvider.notifier).state = SortOption.recommended;
                }
                context.go(AppRoutes.listings);
              } else {
                ref.read(selectedCategoryProvider.notifier).state = null;
              }
            },
          );
        },
      ),
    );
  }
}

// ─── Hotel section ────────────────────────────────────────────────────────────

class _HotelSection extends StatelessWidget {
  const _HotelSection({required this.title, required this.icon, required this.iconColor, required this.hotels});

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Hotel> hotels;

  @override
  Widget build(BuildContext context) {
    if (hotels.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 360,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              cacheExtent: 200,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              itemCount: hotels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                final hotel = hotels[i];
                return SizedBox(
                  width: 270,
                  child: PropertyCard(
                    hotel: hotel,
                    onTap: () => showHotelDetailSheet(ctx, hotel),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
