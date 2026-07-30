import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/features/venues/presentation/bloc/venue_bloc.dart';
import 'package:eventflow_app/core/widgets/premium_card.dart';
import 'package:eventflow_app/core/widgets/status_chip.dart';
import 'package:eventflow_app/core/widgets/section_header.dart';
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

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.success;
      case 'INACTIVE':
        return AppColors.textHint;
      case 'MAINTENANCE':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Venue Detail',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
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
                  final statusColor = _statusColor(venue.status);
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<VenueBloc>().add(LoadVenueDetail(id: widget.id));
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(
                              AppDimens.lg,
                              AppDimens.sm,
                              AppDimens.lg,
                              AppDimens.md,
                            ),
                            padding: const EdgeInsets.all(AppDimens.xxl),
                            decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                                    boxShadow: AppColors.softShadow,
                                  ),
                                  child: const Icon(
                                    Icons.location_city_rounded,
                                    color: Colors.white,
                                    size: AppDimens.iconXl,
                                  ),
                                ),
                                const SizedBox(height: AppDimens.lg),
                                Text(
                                  venue.name,
                                  style: const TextStyle(
                                    fontSize: AppDimens.fontXxl,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppDimens.sm),
                                StatusChip(
                                  label: Formatters.statusLabel(venue.status),
                                  color: statusColor,
                                ),
                              ],
                            ),
                          ),

                          const SectionHeader(title: 'Venue Details'),
                          PremiumCard(
                            margin: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  icon: Icons.category_rounded,
                                  label: 'Type',
                                  value: Formatters.capitalize(venue.venueType),
                                ),
                                const Divider(height: 24, color: AppColors.borderLight),
                                _buildDetailRow(
                                  icon: Icons.people_rounded,
                                  label: 'Capacity',
                                  value: '${venue.capacity} guests',
                                ),
                                if (venue.address != null && venue.address!.isNotEmpty) ...[
                                  const Divider(height: 24, color: AppColors.borderLight),
                                  _buildDetailRow(
                                    icon: Icons.location_on_outlined,
                                    label: 'Address',
                                    value: venue.address!,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SectionHeader(title: 'Pricing'),
                          PremiumCard(
                            margin: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
                            child: Column(
                              children: [
                                _buildPricingRow(
                                  label: 'Weekday',
                                  amount: Formatters.currency(venue.weekdayPrice),
                                  color: AppColors.info,
                                ),
                                const Divider(height: 24, color: AppColors.borderLight),
                                _buildPricingRow(
                                  label: 'Weekend',
                                  amount: Formatters.currency(venue.weekendPrice),
                                  color: AppColors.secondary,
                                ),
                                const Divider(height: 24, color: AppColors.borderLight),
                                _buildPricingRow(
                                  label: 'Peak Season',
                                  amount: Formatters.currency(venue.peakPrice),
                                  color: AppColors.accent,
                                ),
                              ],
                            ),
                          ),

                          if (venue.description != null && venue.description!.isNotEmpty) ...[
                            const SectionHeader(title: 'Description'),
                            PremiumCard(
                              margin: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
                              child: Text(
                                venue.description!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                  fontSize: AppDimens.fontMd,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppDimens.xxl),
                        ],
                      ),
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: Icon(icon, size: AppDimens.iconSm, color: AppColors.primary),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppDimens.fontSm,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: AppDimens.fontMd,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingRow({
    required String label,
    required String amount,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: AppDimens.fontMd,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: AppDimens.fontMd,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
