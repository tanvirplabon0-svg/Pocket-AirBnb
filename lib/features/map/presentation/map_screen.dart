import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../data/models/hotel.dart';
import '../../../providers/hotel_provider.dart';
import '../../../shared/widgets/app_image.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  late final PageController _pageController;
  
  int _selectedIndex = 0;
  bool _showCarousel = true;
  String _tileStyle = 'voyager'; // 'voyager', 'light', 'dark'

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _getTileUrl() {
    switch (_tileStyle) {
      case 'light':
        return 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';
      case 'dark':
        return 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';
      case 'voyager':
      default:
        return 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';
    }
  }

  void _onSelectHotel(int index, List<Hotel> geocodedHotels, {bool animatePage = true}) {
    if (index < 0 || index >= geocodedHotels.length) return;

    setState(() {
      _selectedIndex = index;
      _showCarousel = true;
    });

    final hotel = geocodedHotels[index];
    if (hotel.hasCoords) {
      _mapController.move(
        LatLng(hotel.lat!, hotel.lng!),
        14.0,
      );
    }

    if (animatePage && _pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Map<String, LatLng> _computeSpacedCoordinates(List<Hotel> geocodedHotels) {
    final Map<String, LatLng> result = {};
    final List<Hotel> processed = [];

    for (final h in geocodedHotels) {
      double lat = h.lat!;
      double lng = h.lng!;

      int clusterIndex = 0;
      for (final prev in processed) {
        final prevLat = result[prev.id]!.latitude;
        final prevLng = result[prev.id]!.longitude;
        if ((lat - prevLat).abs() < 0.005 && (lng - prevLng).abs() < 0.005) {
          clusterIndex++;
        }
      }

      if (clusterIndex > 0) {
        // Micro-offset nearby markers along alternating ladder axes so rates fan out cleanly
        final shiftLat = (clusterIndex % 2 == 1 ? 0.0016 : -0.0016) * ((clusterIndex + 1) ~/ 2);
        final shiftLng = (clusterIndex % 2 == 0 ? 0.0014 : -0.0014) * ((clusterIndex + 1) ~/ 2);
        lat += shiftLat;
        lng += shiftLng;
      }

      result[h.id] = LatLng(lat, lng);
      processed.add(h);
    }
    return result;
  }

  void _fitAllBounds(List<Hotel> geocodedHotels) {
    if (geocodedHotels.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(
      geocodedHotels.map((h) => LatLng(h.lat!, h.lng!)).toList(),
    );
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 220),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotelsAsync = ref.watch(hotelsProvider);
    final formatter = ref.watch(currencyFormatterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Row(
          children: [
            const Icon(Icons.map_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Explore Properties Map',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Map Theme Switcher Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.layers_outlined, color: Colors.white),
            tooltip: 'Change Map Style',
            onSelected: (style) {
              setState(() => _tileStyle = style);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'voyager',
                child: Row(
                  children: [
                    Icon(Icons.explore_outlined, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Vibrant (Voyager)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'light',
                child: Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Text('Clean Light'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dark',
                child: Row(
                  children: [
                    Icon(Icons.nightlight_round_outlined, color: Colors.indigo, size: 18),
                    SizedBox(width: 8),
                    Text('Dark Mode'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: hotelsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Could not load hotels map: $e',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        data: (hotels) {
          final geocoded = hotels.where((h) => h.hasCoords).toList();
          // Sort hotels descending so most expensive hotels (e.g. 22500, 19500) appear first in carousel & initial selection
          geocoded.sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));

          if (geocoded.isEmpty) {
            return Center(
              child: Text(
                'No hotels with location coordinates found.',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            );
          }

          if (_selectedIndex >= geocoded.length) {
            _selectedIndex = 0;
          }

          // Compute draw order (z-index): cheap hotels drawn underneath, expensive hotels on top, selected marker at very top
          final drawOrder = List.generate(geocoded.length, (i) => i);
          drawOrder.sort((a, b) {
            if (a == _selectedIndex) return 1;
            if (b == _selectedIndex) return -1;
            return geocoded[a].pricePerNight.compareTo(geocoded[b].pricePerNight);
          });

          final spacedCoords = _computeSpacedCoordinates(geocoded);

          // Ensure valid bounds
          final initialCenter = geocoded.isNotEmpty
              ? LatLng(geocoded.first.lat!, geocoded.first.lng!)
              : const LatLng(23.8103, 90.4125);

          return Stack(
            children: [
              // 1. Dynamic Map View Layer
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 8.5,
                  minZoom: 4.0,
                  maxZoom: 18.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _getTileUrl(),
                    userAgentPackageName: 'com.example.stay_bd',
                    maxZoom: 19,
                  ),

                  // Map Markers Layer with Hotel Rates (layered so expensive/selected rates draw on top)
                  MarkerLayer(
                    markers: drawOrder.map((index) {
                      final h = geocoded[index];
                      final isSelected = index == _selectedIndex;
                      final priceText = formatter.format(h.pricePerNight);
                      final pt = spacedCoords[h.id] ?? LatLng(h.lat!, h.lng!);

                      return Marker(
                        point: pt,
                        width: isSelected ? 96 : 82,
                        height: isSelected ? 44 : 36,
                        child: GestureDetector(
                          onTap: () => _onSelectHotel(index, geocoded),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                width: isSelected ? 2 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? const Color(0xFFE11D48).withOpacity(0.4)
                                      : Colors.black.withOpacity(0.25),
                                  blurRadius: isSelected ? 10 : 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 2),
                                      child: Icon(
                                        Icons.location_on,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  Flexible(
                                    child: Text(
                                      priceText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                        fontWeight: FontWeight.w800,
                                        fontSize: isSelected ? 12 : 10.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // 2. Top Controls & Counter Overlay
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Count Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF334155)),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${geocoded.length} Properties Mapped',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Reset Fit Bounds Button
                        InkWell(
                          onTap: () => _fitAllBounds(geocoded),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF334155)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.center_focus_strong, color: AppColors.primary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Fit All',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Quick City Jump Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _CityJumpChip(
                            label: "Cox's Bazar 🏖️",
                            highlight: true,
                            onTap: () {
                              _mapController.move(const LatLng(21.4190, 91.9805), 14.5);
                            },
                          ),
                          const SizedBox(width: 8),
                          _CityJumpChip(
                            label: 'Dhaka 🏙️',
                            highlight: true,
                            onTap: () {
                              _mapController.move(const LatLng(23.7900, 90.4100), 12.8);
                            },
                          ),
                          const SizedBox(width: 8),
                          _CityJumpChip(
                            label: 'Uttara (Sec 14) 📍',
                            highlight: true,
                            onTap: () {
                              _mapController.move(const LatLng(23.8824, 90.3878), 15.0);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Floating Bottom Hotel Preview Carousel Card
              if (_showCarousel)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle Hide Carousel Floating Pill
                      GestureDetector(
                        onTap: () => setState(() => _showCarousel = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Horizontal PageView of Hotels
                      SizedBox(
                        height: 124,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: geocoded.length,
                          onPageChanged: (index) {
                            _onSelectHotel(index, geocoded, animatePage: false);
                          },
                          itemBuilder: (context, index) {
                            final hotel = geocoded[index];
                            final isSelected = index == _selectedIndex;

                            return AnimatedScale(
                              scale: isSelected ? 1.0 : 0.94,
                              duration: const Duration(milliseconds: 200),
                              child: GestureDetector(
                                onTap: () => context.push(
                                  '${AppRoutes.hotelDetail}/${hotel.id}',
                                  extra: hotel,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFFE2E8F0),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? AppColors.primary.withOpacity(0.2)
                                            : Colors.black.withOpacity(0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      // Image Preview
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: 104,
                                          height: double.infinity,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              hotel.primaryImage.isNotEmpty
                                                  ? AppImage(
                                                      url: hotel.primaryImage,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      color: Colors.grey[200],
                                                      child: const Icon(
                                                        Icons.hotel,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                              // Rating Badge
                                              if (hotel.rating > 0)
                                                Positioned(
                                                  top: 6,
                                                  left: 6,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.75),
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.star,
                                                          color: Colors.amber,
                                                          size: 11,
                                                        ),
                                                        const SizedBox(width: 2),
                                                        Text(
                                                          hotel.rating.toStringAsFixed(1),
                                                          style: GoogleFonts.inter(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Hotel Text Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              hotel.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on_outlined,
                                                  size: 13,
                                                  color: Color(0xFF64748B),
                                                ),
                                                const SizedBox(width: 2),
                                                Expanded(
                                                  child: Text(
                                                    hotel.location,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: const Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),

                                            // Price & Action Button
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      formatter.format(hotel.pricePerNight),
                                                      style: GoogleFonts.inter(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                    Text(
                                                      'per night',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 9,
                                                        color: const Color(0xFF94A3B8),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'View',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      const Icon(
                                                        Icons.chevron_right,
                                                        size: 14,
                                                        color: Colors.white,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Button to reveal carousel again if hidden
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () => setState(() => _showCarousel = true),
                    backgroundColor: AppColors.primary,
                    icon: const Icon(Icons.hotel, color: Colors.white, size: 18),
                    label: Text(
                      'Show Cards',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CityJumpChip extends StatelessWidget {
  const _CityJumpChip({
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.primary
              : const Color(0xFF0F172A).withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight ? Colors.white : const Color(0xFF334155),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
