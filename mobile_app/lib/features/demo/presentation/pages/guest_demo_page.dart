import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/core/widgets/glass_card.dart';
import 'package:eventflow_app/core/widgets/premium_card.dart';
import 'package:eventflow_app/core/widgets/section_header.dart';
import 'package:eventflow_app/core/services/demo_data_provider.dart';
import 'package:eventflow_app/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:eventflow_app/features/dashboard/presentation/widgets/recent_booking_card.dart';

class GuestDemoPage extends StatelessWidget {
  const GuestDemoPage({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final demo = DemoDataProvider();
    final dashboard = demo.dashboard;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildDemoBanner(context)),
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildStatsSection(context, dashboard)),
          SliverToBoxAdapter(child: _buildScheduleSection(context)),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Recent Bookings',
              padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.xxl, AppDimens.lg, AppDimens.md),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final booking = dashboard.recentBookings[index];
                return RecentBookingCard(booking: booking);
              },
              childCount: dashboard.recentBookings.length,
            ),
          ),
          SliverToBoxAdapter(child: _buildSignUpPrompt(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildDemoBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.warning, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 11, color: Colors.white),
                SizedBox(width: 3),
                Text(
                  'GUEST',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: const Text(
              'DEMO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Exploring EventFlow. Sign up to manage real data.',
              style: TextStyle(
                fontSize: AppDimens.fontSm,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.lg, AppDimens.lg, AppDimens.xxl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()} 👋',
                  style: const TextStyle(
                    fontSize: AppDimens.fontLg,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.xs),
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: AppDimens.fontDisplay,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppDimens.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.borderLight, width: 1),
              boxShadow: AppColors.cardShadow,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
              size: AppDimens.iconMd,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, dynamic dashboard) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int columns;
        double aspectRatio;
        if (screenWidth >= 900) {
          columns = 4;
          aspectRatio = 1.8;
        } else if (screenWidth >= 600) {
          columns = 3;
          aspectRatio = 1.6;
        } else {
          columns = 2;
          aspectRatio = 1.5;
        }

        final stats = [
          StatCard(
            title: 'Revenue',
            value: Formatters.currency(dashboard.totalRevenue),
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.success,
          ),
          StatCard(
            title: 'Bookings',
            value: dashboard.totalBookings.toString(),
            icon: Icons.event_available_rounded,
            color: AppColors.primary,
          ),
          StatCard(
            title: 'Leads',
            value: dashboard.totalLeads.toString(),
            icon: Icons.people_outline_rounded,
            color: AppColors.warning,
          ),
          StatCard(
            title: 'Pending',
            value: Formatters.currency(dashboard.pendingPayments),
            icon: Icons.pending_actions_rounded,
            color: AppColors.error,
          ),
        ];

        return Column(
          children: [
            SectionHeader(
              title: 'Overview',
              padding: const EdgeInsets.fromLTRB(AppDimens.lg, 0, AppDimens.lg, AppDimens.md),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
              child: GridView.count(
                crossAxisCount: columns,
                mainAxisSpacing: AppDimens.md,
                crossAxisSpacing: AppDimens.md,
                childAspectRatio: aspectRatio,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: stats,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScheduleSection(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: "Today's Schedule",
          padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.xxl, AppDimens.lg, AppDimens.md),
        ),
        PremiumCard(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.06),
              AppColors.secondary.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12), width: 1),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: const Icon(Icons.today_rounded, color: Colors.white, size: AppDimens.iconLg),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You have no events scheduled today',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: AppDimens.fontMd,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.xs),
                    Text(
                      'Enjoy your free day or plan something new!',
                      style: TextStyle(
                        fontSize: AppDimens.fontSm,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpPrompt(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.xxl, AppDimens.lg, 0),
      padding: const EdgeInsets.all(AppDimens.xxl),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: AppDimens.md),
          const Text(
            'Ready to manage your events?',
            style: TextStyle(
              fontSize: AppDimens.fontMd,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.xs),
          Text(
            'Create a free account to access all features',
            style: TextStyle(
              fontSize: AppDimens.fontSm,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.lg),
          SizedBox(
            width: double.infinity,
            height: AppDimens.buttonHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                boxShadow: AppColors.softShadow,
              ),
              child: ElevatedButton(
                onPressed: () => context.go('/signup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: AppDimens.fontBase,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
