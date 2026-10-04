import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.explore_outlined,
      title: 'Discover Bangladesh Stays',
      subtitle:
          'From sea-view suites in Cox\'s Bazar to heritage hotels in Old Dhaka — find your perfect stay.',
      accentColor: AppColors.primary,
    ),
    _OnboardingPage(
      icon: Icons.currency_exchange_outlined,
      title: 'Compare Prices in BDT',
      subtitle:
          'All prices in Bangladeshi Taka. Filter by budget, location and amenities — no surprises.',
      accentColor: AppColors.riverBlue,
    ),
    _OnboardingPage(
      icon: Icons.favorite_outline,
      title: 'Save & Chat with AI',
      subtitle:
          'Heart your favourites, then ask our AI assistant for personalised hotel recommendations.',
      accentColor: AppColors.accentWarm,
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text('Skip',
                      style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            const SizedBox(height: 24),
            // Indicators
            SmoothPageIndicator(
              controller: _ctrl,
              count: _pages.length,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3,
                activeDotColor: _pages[_page].accentColor,
                dotColor: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            const SizedBox(height: 32),
            // CTA button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  backgroundColor: _pages[_page].accentColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _page < _pages.length - 1 ? 'Next' : 'Get Started',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text(
                'Already have an account? Log in',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: accentColor),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
