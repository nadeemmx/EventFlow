import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:eventflow_app/injector.dart';
import 'package:eventflow_app/core/services/notification_service.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/storage/storage_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      title: 'Find the Perfect\nVenue',
      subtitle: 'Discover amazing lawns, banquet halls,\nand event spaces for every occasion.',
      icon: Icons.location_on_rounded,
      color: Color(0xFFD4A843),
    ),
    _OnboardingData(
      title: 'Celebrate Every\nOccasion',
      subtitle: 'Weddings, birthdays, corporate events,\nand more — all in one place.',
      icon: Icons.celebration_rounded,
      color: Color(0xFFC48B6A),
    ),
    _OnboardingData(
      title: 'Hassle-Free\nBooking',
      subtitle: 'Easy search, transparent pricing,\nand instant confirmation.',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF7A9E7E),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    await sl<StorageService>().setOnboardingCompleted();
    // First-run opt-in point for the push permission prompt: unlike cold
    // start, the user is looking at the UI here.
    try {
      await sl<NotificationService>().requestPermission();
    } catch (_) {
      // Permission prompt is best effort (e.g. Firebase not configured).
    }
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: DesignSystem.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  HapticFeedback.lightImpact();
                },
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration
                        Container(
                          width: screenHeight * 0.28,
                          height: screenHeight * 0.28,
                          decoration: BoxDecoration(
                            color: data.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: screenHeight * 0.18,
                              height: screenHeight * 0.18,
                              decoration: BoxDecoration(
                                color: data.color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                data.icon,
                                size: screenHeight * 0.09,
                                color: data.color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Title
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: DesignSystem.headlineLarge.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Subtitle
                        Text(
                          data.subtitle,
                          textAlign: TextAlign.center,
                          style: DesignSystem.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom section
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Get Started / Next button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: DesignSystem.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Create Account link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: DesignSystem.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Sign In',
                          style: DesignSystem.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}

class _OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
