import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/core/widgets/loading_widget.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/demo_banner.dart';
import 'package:eventflow_app/core/widgets/glass_card.dart';
import 'package:eventflow_app/core/widgets/premium_card.dart';
import 'package:eventflow_app/core/widgets/section_header.dart';
import 'package:eventflow_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:eventflow_app/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:eventflow_app/features/dashboard/presentation/widgets/recent_booking_card.dart';
import 'package:eventflow_app/features/dashboard/presentation/widgets/revenue_chart.dart';
import 'package:eventflow_app/features/dashboard/presentation/widgets/booking_trend_chart.dart';
import 'package:eventflow_app/features/dashboard/presentation/widgets/lead_conversion_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboard());
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const ShimmerGrid();
          }
          if (state is DashboardError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<DashboardBloc>().add(LoadDashboard()),
            );
          }
          if (state is DashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(RefreshDashboard());
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: const DemoBanner()),
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverToBoxAdapter(child: _buildStatsSection(context, state)),
                  SliverToBoxAdapter(child: _buildScheduleSection(context)),
                  SliverToBoxAdapter(child: _buildQuickActionsSection(context)),
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Revenue Overview',
                      padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.xxl, AppDimens.lg, AppDimens.md),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: GlassCard(
                      margin: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
                      padding: const EdgeInsets.all(AppDimens.lg),
                      child: RevenueChart(data: state.dashboard.monthlyRevenue),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Booking Trend',
                      padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.xxl, AppDimens.lg, AppDimens.md),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: GlassCard(
                      margin: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
                      padding: const EdgeInsets.all(AppDimens.lg),
                      child: BookingTrendChart(
                        data: state.dashboard.monthlyRevenue.map((m) => m.amount / 10000).toList(),
                        labels: state.dashboard.monthlyRevenue.map((m) => m.month).toList(),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Lead Conversion',
                      padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.xxl, AppDimens.lg, AppDimens.md),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: GlassCard(
                      margin: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
                      padding: const EdgeInsets.all(AppDimens.lg),
                      child: Column(
                        children: [
                          LeadConversionChart(
                            converted: state.dashboard.totalLeads ~/ 3,
                            lost: state.dashboard.totalLeads ~/ 4,
                            pending: state.dashboard.totalLeads -
                                (state.dashboard.totalLeads ~/ 3) -
                                (state.dashboard.totalLeads ~/ 4),
                          ),
                          const SizedBox(height: AppDimens.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _legendItem(AppColors.success, 'Converted'),
                              _legendItem(AppColors.error, 'Lost'),
                              _legendItem(AppColors.warning, 'Pending'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Recent Bookings',
                      actionLabel: 'View All',
                      onAction: () => context.push('/bookings'),
                      padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.xxl, AppDimens.lg, AppDimens.md),
                    ),
                  ),
                  if (state.dashboard.recentBookings.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No recent bookings',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: AppDimens.fontSm),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final booking = state.dashboard.recentBookings[index];
                          return RecentBookingCard(
                            booking: booking,
                            onTap: () => context.push('/bookings/${booking.id}'),
                          );
                        },
                        childCount: state.dashboard.recentBookings.length,
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
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Container(
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, DashboardLoaded state) {
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
            value: Formatters.currency(state.dashboard.totalRevenue),
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.success,
          ),
          StatCard(
            title: 'Bookings',
            value: state.dashboard.totalBookings.toString(),
            icon: Icons.event_available_rounded,
            color: AppColors.primary,
            onTap: () => context.push('/bookings'),
          ),
          StatCard(
            title: 'Leads',
            value: state.dashboard.totalLeads.toString(),
            icon: Icons.people_outline_rounded,
            color: AppColors.warning,
            onTap: () => context.push('/leads'),
          ),
          StatCard(
            title: 'Pending',
            value: Formatters.currency(state.dashboard.pendingPayments),
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
          actionLabel: 'See All',
          onAction: () => context.push('/bookings'),
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

  Widget _buildQuickActionsSection(BuildContext context) {
    final actions = [
      _QuickAction('New Booking', Icons.add_circle_outline_rounded, AppColors.primary, () => context.push('/bookings')),
      _QuickAction('Add Lead', Icons.person_add_outlined, AppColors.success, () => context.push('/leads')),
      _QuickAction('Invoices', Icons.receipt_long_outlined, AppColors.warning, () => context.push('/invoices')),
      _QuickAction('Venues', Icons.location_city_outlined, AppColors.info, () => context.push('/venues')),
    ];

    return Column(
      children: [
        const SectionHeader(
          title: 'Quick Actions',
          padding: EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.xxl, AppDimens.lg, AppDimens.md),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
          child: Row(
            children: actions.map((action) {
              return Expanded(
                child: GestureDetector(
                  onTap: action.onTap,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: AppDimens.lg, horizontal: AppDimens.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                      border: Border.all(color: AppColors.borderLight, width: 1),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: action.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          ),
                          child: Icon(action.icon, color: action.color, size: AppDimens.iconLg),
                        ),
                        const SizedBox(height: AppDimens.sm),
                        Text(
                          action.label,
                          style: const TextStyle(
                            fontSize: AppDimens.fontSm,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppDimens.fontSm,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(this.label, this.icon, this.color, this.onTap);
}
