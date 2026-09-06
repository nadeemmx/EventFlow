import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/features/venues/presentation/bloc/venue_bloc.dart';
import 'package:eventflow_app/core/widgets/status_chip.dart';
import 'package:eventflow_app/core/widgets/demo_banner.dart';

class VenueDetailPage extends StatefulWidget {
  final int id;
  const VenueDetailPage({super.key, required this.id});

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<VenueBloc>().add(LoadVenueDetail(id: widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const DemoBanner(),
          Expanded(
            child: BlocBuilder<VenueBloc, VenueState>(
              builder: (context, state) {
                if (state is VenuesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is VenueDetailLoaded) {
                  final venue = state.venue;
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<VenueBloc>().add(LoadVenueDetail(id: widget.id));
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // ─── Hero Image ──────────────────────────
                        SliverAppBar(
                          expandedHeight: 260,
                          pinned: true,
                          backgroundColor: AppColors.background,
                          surfaceTintColor: Colors.transparent,
                          leading: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                boxShadow: DesignSystem.shadowSm,
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                          actions: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                margin: const EdgeInsets.all(12),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: DesignSystem.shadowSm,
                                ),
                                child: const Icon(
                                  Icons.favorite_border_rounded,
                                  color: AppColors.textPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                            background: Container(
                              decoration: BoxDecoration(
                                gradient: DesignSystem.warmGradient,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_city_rounded,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      venue.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    StatusChip(
                                      label: Formatters.statusLabel(venue.status),
                                      color: Colors.white,
                                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                                      small: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ─── Content ─────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Venue type and capacity
                                Row(
                                  children: [
                                    _buildInfoChip(
                                      icon: Icons.category_rounded,
                                      label: Formatters.capitalize(venue.venueType),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      icon: Icons.people_rounded,
                                      label: '${venue.capacity} guests',
                                    ),
                                  ],
                                ),
                                if (venue.address != null && venue.address!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          venue.address!,
                                          style: DesignSystem.bodyMedium.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 24),

                                // Description
                                if (venue.description != null && venue.description!.isNotEmpty) ...[
                                  Text(
                                    'Description',
                                    style: DesignSystem.titleMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    venue.description!,
                                    style: DesignSystem.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Pricing
                                Text(
                                  'Pricing',
                                  style: DesignSystem.titleMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPricingCard(
                                  label: 'Weekday',
                                  amount: Formatters.currency(venue.weekdayPrice),
                                  color: AppColors.info,
                                ),
                                const SizedBox(height: 8),
                                _buildPricingCard(
                                  label: 'Weekend',
                                  amount: Formatters.currency(venue.weekendPrice),
                                  color: AppColors.accent,
                                ),
                                const SizedBox(height: 8),
                                _buildPricingCard(
                                  label: 'Peak Season',
                                  amount: Formatters.currency(venue.peakPrice),
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (state is VenueError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<VenueBloc>().add(LoadVenueDetail(id: widget.id)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: DesignSystem.labelMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String label,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: DesignSystem.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            amount,
            style: DesignSystem.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
