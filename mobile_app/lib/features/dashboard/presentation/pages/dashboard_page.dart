import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:eventflow_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:eventflow_app/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:eventflow_app/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:eventflow_app/features/dashboard/presentation/widgets/recent_booking_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadDashboardIfNeeded();
  }

  void _loadDashboardIfNeeded() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final dashboardState = context.read<DashboardBloc>().state;
      if (dashboardState is DashboardInitial) {
        context.read<DashboardBloc>().add(LoadDashboard());
      }
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState is AuthAuthenticated) {
          final dashboardState = context.read<DashboardBloc>().state;
          if (dashboardState is DashboardInitial || dashboardState is DashboardError) {
            context.read<DashboardBloc>().add(LoadDashboard());
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: DesignSystem.spacing4),
                    Text(
                      'Please log in to view your dashboard',
                      style: DesignSystem.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: DesignSystem.spacing6),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            body: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading) {
                  return const DashboardSkeleton();
                }

                if (state is DashboardError) {
                  return _buildErrorState(context, state.message);
                }

                if (state is DashboardLoaded) {
                  final dashboard = state.dashboard;
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async {
                      context.read<DashboardBloc>().add(RefreshDashboard());
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        // ─── Header / Greeting ───────────────────
                        SliverToBoxAdapter(child: _buildHeader(context, authState)),

                        // ─── Stats Summary ───────────────────────
                        SliverToBoxAdapter(
                          child: _buildStatsSection(context, dashboard),
                        ),

                        // ─── Schedule / Upcoming ─────────────────
                        SliverToBoxAdapter(
                          child: _buildScheduleSection(context, dashboard),
                        ),

                        // ─── Quick Actions ──────────────────────
                        SliverToBoxAdapter(
                          child: _buildQuickActions(context),
                        ),

                        // ─── Recent Bookings ────────────────────
                        SliverToBoxAdapter(
                          child: _buildRecentBookingsHeader(context),
                        ),

                        if (dashboard.recentBookings.isEmpty)
                          SliverToBoxAdapter(
                            child: _buildEmptyBookings(context),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final booking = dashboard.recentBookings[index];
                                return RecentBookingCard(
                                  booking: booking,
                                  onTap: () => context.push('/bookings/${booking.id}'),
                                );
                              },
                              childCount: dashboard.recentBookings.length,
                            ),
                          ),

                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          );
        },
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AuthAuthenticated authState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: DesignSystem.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authState.user.fullName.split(' ').first,
                  style: DesignSystem.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                border: Border.all(
                  color: AppColors.borderLight,
                ),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 22,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: DesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
              ),
              child: Center(
                child: Text(
                  (authState.user.fullName.isNotEmpty
                      ? authState.user.fullName[0]
                      : 'U')
                      .toUpperCase(),
                  style: DesignSystem.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats ───────────────────────────────────────────────────────
  Widget _buildStatsSection(BuildContext context, dynamic dashboard) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          StatCard(
            title: 'Revenue',
            value: Formatters.currency(dashboard.totalRevenue),
            icon: Icons.account_balance_wallet_rounded,
            color: DesignSystem.success,
          ),
          StatCard(
            title: 'Bookings',
            value: dashboard.totalBookings.toString(),
            icon: Icons.event_available_rounded,
            color: AppColors.primary,
            onTap: () => context.push('/bookings'),
          ),
          StatCard(
            title: 'Leads',
            value: dashboard.totalLeads.toString(),
            icon: Icons.people_outline_rounded,
            color: DesignSystem.warning,
            onTap: () => context.push('/leads'),
          ),
          StatCard(
            title: 'Pending',
            value: Formatters.currency(dashboard.pendingPayments),
            icon: Icons.pending_actions_rounded,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  // ─── Schedule ────────────────────────────────────────────────────
  Widget _buildScheduleSection(BuildContext context, dynamic dashboard) {
    final hasUpcoming = dashboard.upcomingEvents.isNotEmpty;
    final nextEvent = hasUpcoming ? dashboard.upcomingEvents.first : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Schedule",
            style: DesignSystem.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
            child: InkWell(
              onTap: () => context.push('/bookings'),
              borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: hasUpcoming
                            ? DesignSystem.primaryGradient
                            : LinearGradient(
                                colors: [
                                  AppColors.primarySurface,
                                  AppColors.primarySurface,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                      ),
                      child: Icon(
                        hasUpcoming ? Icons.event_rounded : Icons.event_available_rounded,
                        color: hasUpcoming ? Colors.white : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasUpcoming
                                ? nextEvent!.customerName
                                : 'No events scheduled today',
                            style: DesignSystem.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasUpcoming
                                ? '${nextEvent!.eventDate}  ·  ${nextEvent!.venueName ?? 'No venue'}'
                                : 'Enjoy your free day or plan something new',
                            style: DesignSystem.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Actions ───────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        label: 'New Booking',
        icon: Icons.add_circle_outline_rounded,
        color: AppColors.primary,
        onTap: () => context.push('/bookings'),
      ),
      _QuickAction(
        label: 'Add Lead',
        icon: Icons.person_add_outlined,
        color: DesignSystem.success,
        onTap: () => context.push('/leads'),
      ),
      _QuickAction(
        label: 'Invoices',
        icon: Icons.receipt_long_outlined,
        color: DesignSystem.warning,
        onTap: () => context.push('/invoices'),
      ),
      _QuickAction(
        label: 'Venues',
        icon: Icons.location_city_outlined,
        color: AppColors.info,
        onTap: () => context.push('/venues'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: DesignSystem.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: actions.map((action) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        action.onTap();
                      },
                      borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: action.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
                              ),
                              child: Icon(
                                action.icon,
                                color: action.color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              action.label,
                              style: DesignSystem.labelSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Recent Bookings Header ──────────────────────────────────────
  Widget _buildRecentBookingsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Text(
            'Recent Bookings',
            style: DesignSystem.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => context.push('/bookings'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View All',
              style: DesignSystem.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty Bookings ──────────────────────────────────────────────
  Widget _buildEmptyBookings(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookings yet',
            style: DesignSystem.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first booking to get started',
            style: DesignSystem.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/bookings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Booking'),
          ),
        ],
      ),
    );
  }

  // ─── Error State ─────────────────────────────────────────────────
  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load dashboard',
              style: DesignSystem.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: DesignSystem.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(CheckAuthStatus());
                context.read<DashboardBloc>().add(LoadDashboard());
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
