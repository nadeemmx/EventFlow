import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/features/venues/presentation/bloc/venue_bloc.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/empty_state_widget.dart';
import 'package:eventflow_app/core/widgets/status_chip.dart';
import 'package:eventflow_app/core/widgets/demo_banner.dart';

class VenueListPage extends StatefulWidget {
  const VenueListPage({super.key});

  @override
  State<VenueListPage> createState() => _VenueListPageState();
}

class _VenueListPageState extends State<VenueListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<VenueBloc>().add(const LoadVenues());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<VenueBloc>().state;
      if (state is VenuesLoaded && state.hasMore) {
        context.read<VenueBloc>().add(LoadVenues(page: state.currentPage + 1));
      }
    }
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
          'Venues',
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
                if (state is VenuesLoading || state is VenueDetailLoaded) {
                  if (state is VenuesLoading) {
                    return _buildSkeletonList();
                  }
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is VenueError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: () => context.read<VenueBloc>().add(const LoadVenues()),
                  );
                }
                if (state is VenuesLoaded) {
                  if (state.venues.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.location_city_rounded,
                      title: 'No venues found',
                      subtitle: 'Venues will appear here once added',
                      onAction: () => context.read<VenueBloc>().add(const LoadVenues(refresh: true)),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<VenueBloc>().add(const LoadVenues(refresh: true));
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.lg,
                        vertical: AppDimens.sm,
                      ),
                      itemCount: state.venues.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.venues.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppDimens.xl),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final venue = state.venues[index];
                        final statusColor = _statusColor(venue.status);
                        return _buildVenueCard(venue, statusColor);
                      },
                    ),
                  );
                }
                return _buildSkeletonList();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueCard(dynamic venue, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
        child: InkWell(
          onTap: () => context.push('/venues/${venue.id}'),
          borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppDimens.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: DesignSystem.primaryGradient,
                    borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                  ),
                  child: const Icon(
                    Icons.location_city_rounded,
                    color: Colors.white,
                    size: AppDimens.iconLg,
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: AppDimens.fontBase,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Formatters.capitalize(venue.venueType)}  ·  ${venue.capacity} capacity',
                        style: const TextStyle(
                          fontSize: AppDimens.fontSm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(venue.weekdayPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: AppDimens.fontMd,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.xs),
                    StatusChip(
                      label: Formatters.statusLabel(venue.status),
                      color: statusColor,
                      small: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.lg),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 140,
                      decoration: BoxDecoration(
                        color: AppColors.ivory,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
                      ),
                    ),
                    const SizedBox(height: AppDimens.sm),
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.ivory,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
