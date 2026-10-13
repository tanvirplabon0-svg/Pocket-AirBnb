import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../core/widgets/skeleton_card.dart';
import '../../../data/models/hotel.dart';
import '../../../data/models/room_availability.dart';
import '../../../providers/hotel_provider.dart';
import '../../../shared/widgets/hotel_card.dart';

class ListingsScreen extends ConsumerStatefulWidget {
  const ListingsScreen({super.key});

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
  final _searchCtrl = TextEditingController();
  bool _groupByPrice = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredHotelsProvider);
    final sortOpt = ref.watch(sortOptionProvider);
    final selectedCity = ref.watch(selectedCityProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);

    final priceRange = ref.watch(priceRangeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
        titleSpacing: 0,
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) =>
                ref.read(searchQueryProvider.notifier).state = v,
            decoration: InputDecoration(
              hintText: 'Search hotels, cities...',
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openFilters,
            tooltip: 'Filters',
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            initialValue: sortOpt,
            onSelected: (v) =>
                ref.read(sortOptionProvider.notifier).state = v,
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: SortOption.recommended, child: Text('Recommended')),
              PopupMenuItem(
                  value: SortOption.priceLowHigh, child: Text('Price: Low → High')),
              PopupMenuItem(
                  value: SortOption.priceHighLow, child: Text('Price: High → Low')),
              PopupMenuItem(
                  value: SortOption.ratingHighLow, child: Text('Top Rated')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filter chips
          if (selectedCity != null || selectedCat != null || priceRange.start > 0 || priceRange.end < 30000)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  if (selectedCity != null)
                    _ActiveChip(
                      label: selectedCity,
                      onRemove: () => ref
                          .read(selectedCityProvider.notifier)
                          .state = null,
                    ),
                  if (selectedCat != null) ...[
                    const SizedBox(width: 6),
                    _ActiveChip(
                      label: selectedCat,
                      onRemove: () => ref
                          .read(selectedCategoryProvider.notifier)
                          .state = null,
                    ),
                  ],
                  if (priceRange.start > 0 || priceRange.end < 30000) ...[
                    const SizedBox(width: 6),
                    _ActiveChip(
                      label: '৳${priceRange.start.toInt()} - ৳${priceRange.end.toInt()}',
                      onRemove: () => ref
                          .read(priceRangeProvider.notifier)
                          .state = const RangeValues(0, 30000),
                    ),
                  ],
                ],
              ),
            ),
          // Results
          Expanded(
            child: filteredAsync.when(
              loading: () => const SkeletonGrid(count: 6),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (hotels) {
                if (hotels.isEmpty) {
                  return _EmptyState(
                    onReset: () => clearAllFilters(ref),
                  );
                }

                final isBudgetMode = selectedCat?.toLowerCase() == 'budget' || _groupByPrice;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _availabilitySummary(hotels),
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _groupByPrice = !_groupByPrice;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      isBudgetMode ? Icons.grid_view : Icons.view_headline,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isBudgetMode ? 'Grid View' : 'Group by Budget',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: isBudgetMode
                            ? _PriceRangeGroupedView(hotels: hotels)
                            : _HotelGrid(hotels: hotels),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _availabilitySummary(List<Hotel> hotels) {
    final availableCount =
        hotels.where((h) => h.roomAvailability.total > 0).length;
    if (availableCount == hotels.length) {
      return '${hotels.length} stays found';
    }
    return '${hotels.length} stays found · $availableCount available';
  }
}

class _HotelGrid extends StatelessWidget {
  const _HotelGrid({required this.hotels});

  final List<Hotel> hotels;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: hotels.length,
      itemBuilder: (_, i) => HotelCard(hotel: hotels[i]),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      side: const BorderSide(color: AppColors.primary),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'No stays match your filters',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting or clearing your filters.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset filters'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter bottom sheet ──────────────────────────────────────────────────────

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  static const _categories = [
    'Beach',
    'Luxury',
    'Budget',
    'Business',
    'Family',
    'Resort',
    'Boutique',
    'Airport',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(availableCitiesProvider);
    final selectedCity = ref.watch(selectedCityProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final minRating = ref.watch(minRatingProvider);
    final priceRange = ref.watch(priceRangeProvider);
    final formatter = ref.watch(currencyFormatterProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scroll) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filters',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
                TextButton(
                  onPressed: () {
                    clearAllFilters(ref);
                    Navigator.pop(context);
                  },
                  child: const Text('Reset',
                      style: TextStyle(color: AppColors.accentRed)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Category filter
                const Text('Category',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _categories.map((cat) {
                    final isSelected = cat == selectedCat;
                    return FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      onSelected: (_) => ref
                          .read(selectedCategoryProvider.notifier)
                          .state = isSelected ? null : cat,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // City filter
                const Text('City',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: cities.map((c) {
                    final isSelected = c == selectedCity;
                    return FilterChip(
                      label: Text(c),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      onSelected: (_) => ref
                          .read(selectedCityProvider.notifier)
                          .state = isSelected ? null : c,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Min rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Min. Rating',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(
                      minRating == 0
                          ? 'Any'
                          : '${minRating.toStringAsFixed(1)}+',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Slider(
                  value: minRating,
                  min: 0,
                  max: 10,
                  divisions: 20,
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      ref.read(minRatingProvider.notifier).state = v,
                ),
                const SizedBox(height: 12),
                // Price range
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Price Range (${formatter.symbol}/night)',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(
                      '${formatter.format(priceRange.start.toInt())} – ${formatter.format(priceRange.end.toInt())}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Budget Presets Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _BudgetPresetChip(
                        label: 'Under ৳3,000',
                        range: const RangeValues(0, 3000),
                        currentRange: priceRange,
                        onSelect: (r) =>
                            ref.read(priceRangeProvider.notifier).state = r,
                      ),
                      const SizedBox(width: 6),
                      _BudgetPresetChip(
                        label: '৳3,000 – ৳6,000',
                        range: const RangeValues(3000, 6000),
                        currentRange: priceRange,
                        onSelect: (r) =>
                            ref.read(priceRangeProvider.notifier).state = r,
                      ),
                      const SizedBox(width: 6),
                      _BudgetPresetChip(
                        label: '৳6,000 – ৳12,000',
                        range: const RangeValues(6000, 12000),
                        currentRange: priceRange,
                        onSelect: (r) =>
                            ref.read(priceRangeProvider.notifier).state = r,
                      ),
                      const SizedBox(width: 6),
                      _BudgetPresetChip(
                        label: '৳12,000+',
                        range: const RangeValues(12000, 30000),
                        currentRange: priceRange,
                        onSelect: (r) =>
                            ref.read(priceRangeProvider.notifier).state = r,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                RangeSlider(
                  values: priceRange,
                  min: 0,
                  max: 30000,
                  divisions: 60,
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      ref.read(priceRangeProvider.notifier).state = v,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetPresetChip extends StatelessWidget {
  const _BudgetPresetChip({
    required this.label,
    required this.range,
    required this.currentRange,
    required this.onSelect,
  });

  final String label;
  final RangeValues range;
  final RangeValues currentRange;
  final ValueChanged<RangeValues> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = (currentRange.start - range.start).abs() < 100 &&
        (currentRange.end - range.end).abs() < 100;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(isSelected ? const RangeValues(0, 30000) : range),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
      ),
      backgroundColor: theme.cardColor,
      side: BorderSide(
        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
      ),
      showCheckmark: false,
    );
  }
}

class _PriceRangeGroupedView extends StatelessWidget {
  const _PriceRangeGroupedView({required this.hotels});

  final List<Hotel> hotels;

  static const _groups = [
    (
      title: '৳15,000+',
      subtitle: 'Luxury & 5-Star Resorts',
      icon: Icons.diamond_outlined,
      color: Color(0xFFD97706),
      min: 15001.0,
      max: 999999.0,
    ),
    (
      title: '৳8,001 – ৳15,000',
      subtitle: 'Premium & Deluxe Stays',
      icon: Icons.workspace_premium_outlined,
      color: Color(0xFF7C3AED),
      min: 8001.0,
      max: 15000.0,
    ),
    (
      title: '৳5,000 – ৳8,000',
      subtitle: 'Standard & Mid-Range Stays',
      icon: Icons.hotel_outlined,
      color: Color(0xFF2563EB),
      min: 5001.0,
      max: 8000.0,
    ),
    (
      title: 'Under ৳5,000',
      subtitle: 'Economy & Budget Stays',
      icon: Icons.savings_outlined,
      color: Color(0xFF10B981),
      min: 0.0,
      max: 5000.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32, top: 4),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        final groupHotels = (hotels
            .where((h) => h.pricePerNight >= group.min && h.pricePerNight <= group.max)
            .toList())
          ..sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));

        if (groupHotels.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Container(
              margin: const EdgeInsets.fromLTRB(2, 14, 2, 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: group.color.withValues(alpha: isDark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: group.color.withValues(alpha: isDark ? 0.4 : 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: group.color.withValues(alpha: isDark ? 0.3 : 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(group.icon, color: group.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              group.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: group.color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${groupHotels.length} ${groupHotels.length == 1 ? "stay" : "stays"}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          group.subtitle,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Hotels Grid under this range
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: groupHotels.length,
              itemBuilder: (_, i) => HotelCard(hotel: groupHotels[i]),
            ),
          ],
        );
      },
    );
  }
}
