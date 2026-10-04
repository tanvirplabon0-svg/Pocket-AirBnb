import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/shell/presentation/app_shell.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/listings/presentation/listings_screen.dart';
import '../features/hotel_details/presentation/hotel_details_screen.dart';
import '../features/booking/presentation/booking_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/profile/presentation/profile_screen_new.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/trips/presentation/trips_screen.dart';
import '../features/inbox/presentation/inbox_screen.dart';
import '../features/property/presentation/availability_calendar_screen.dart';
import '../features/property/presentation/become_host_screen.dart';
import '../features/property/presentation/host_dashboard_screen.dart';
import '../features/property/presentation/property_form_screen.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../data/models/hotel.dart';
import '../providers/auth_provider.dart';

// Routes that logged-out users can still visit — everything else requires
// a signed-in account.
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.signup,
};

/// ChangeNotifier that fires whenever [authProvider] changes,
/// so GoRouter re-evaluates the redirect on every login/logout.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  bool get isLoggedIn => _ref.read(authProvider).isLoggedIn;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = notifier.isLoggedIn;
      final loc = state.matchedLocation;
      final isPublic = _publicRoutes.contains(loc);

      if (!isLoggedIn && !isPublic) return AppRoutes.login;
      // Signed-in users shouldn't linger on auth/onboarding screens.
      if (isLoggedIn && isPublic && loc != AppRoutes.splash) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, __) => const SignupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home,      builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.listings,  builder: (_, __) => const ListingsScreen()),
          GoRoute(path: AppRoutes.map,       builder: (_, __) => const MapScreen()),
          GoRoute(path: AppRoutes.chat,      builder: (_, __) => const ChatScreen()),
          GoRoute(path: AppRoutes.profile,   builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: AppRoutes.trips,     builder: (_, __) => const TripsScreen()),
      GoRoute(path: AppRoutes.inbox,     builder: (_, __) => const InboxScreen()),
      GoRoute(path: AppRoutes.favorites, builder: (_, __) => const FavoritesScreen()),
      GoRoute(
        path: '${AppRoutes.hotelDetail}/:id',
        builder: (_, state) => HotelDetailsScreen(
          hotelId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '${AppRoutes.booking}/:id',
        builder: (_, state) {
          final hotel = state.extra as Hotel?;
          final id = state.pathParameters['id'] ?? '';
          if (hotel != null) return BookingScreen(hotel: hotel);
          return Scaffold(
            appBar: AppBar(title: const Text('Booking')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text('Hotel $id not found.'),
                ],
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.becomeHost,
        builder: (_, __) => const BecomeHostScreen(),
      ),
      GoRoute(
        path: AppRoutes.hostDashboard,
        builder: (_, __) => const HostDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.propertyForm,
        builder: (_, __) => const PropertyFormScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.propertyAvailability}/:id',
        builder: (_, state) => AvailabilityCalendarScreen(
          propertyId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
    ],
  );
});

abstract final class AppRoutes {
  static const splash      = '/splash';
  static const onboarding  = '/onboarding';
  static const login       = '/auth/login';
  static const signup      = '/auth/signup';
  static const home        = '/';
  static const listings    = '/listings';
  static const map         = '/map';
  static const trips       = '/trips';
  static const inbox       = '/inbox';
  static const favorites   = '/favorites';
  static const chat        = '/chat';
  static const profile     = '/profile';
  static const hotelDetail = '/hotel';
  static const booking     = '/booking';
  static const becomeHost  = '/host/become';
  static const hostDashboard = '/host/dashboard';
  static const propertyForm  = '/host/property';
  static const propertyAvailability = '/host/property/availability';
  static const adminDashboard = '/admin';
}
