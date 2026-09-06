import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/core/widgets/components/eventflow_empty_state.dart';
import 'package:eventflow_app/core/widgets/components/eventflow_error_state.dart';
import 'package:eventflow_app/features/bookings/presentation/bloc/booking_bloc.dart';
import 'package:eventflow_app/features/bookings/presentation/widgets/booking_status_widgets.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

class BookingListPage extends StatefulWidget {
  const BookingListPage({super.key});

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  final _searchController = TextEditingController();
  String _statusFilter = 'ALL';
  final _scrollController = ScrollController();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    context.read<BookingBloc>().add(const LoadBookings());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<BookingBloc>().state;
      if (state is BookingsLoaded && state.hasMore) {
        context.read<BookingBloc>().add(
          LoadBookings(
            page: state.currentPage + 1,
            search: _searchController.text,
            status: _statusFilter == 'ALL' ? null : _statusFilter,
          ),
        );
      }
    }
  }

  bool get _isGuest => context.read<AuthBloc>().state is AuthGuestAuthenticated;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Bookings',
          style: DesignSystem.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                if (_isGuest) {
                  _showLoginRequired(context);
                } else {
                  context.push('/bookings/new');
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: isWideScreen ? const Text('New') : const SizedBox.shrink(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          const SizedBox(height: 4),
          Expanded(
            child: BlocBuilder<BookingBloc, BookingState>(
              builder: (context, state) {
                if (state is BookingsLoading) {
                  return _buildSkeleton();
                }
                if (state is BookingDetailLoaded ||
                    state is BookingActionSuccess) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (state is BookingError) {
                  return EventFlowErrorState.generic(
                    onRetry: () =>
                        context.read<BookingBloc>().add(const LoadBookings()),
                  );
                }
                if (state is BookingsLoaded) {
                  if (state.bookings.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildBookingList(state);
                }
                return _buildSkeleton();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: AnimatedContainer(
        duration: DesignSystem.durationNormal,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
          border: Border.all(
            color: _isSearchFocused ? AppColors.primary : AppColors.border,
            width: _isSearchFocused ? 2 : 1,
          ),
          boxShadow: _isSearchFocused ? DesignSystem.shadowSm : null,
        ),
        child: TextField(
          controller: _searchController,
          style: DesignSystem.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search by name, number, or type...',
            hintStyle: DesignSystem.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 22,
              color: _isSearchFocused ? AppColors.primary : AppColors.textTertiary,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      context.read<BookingBloc>().add(
                        const LoadBookings(refresh: true),
                      );
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (v) {
            context.read<BookingBloc>().add(
              LoadBookings(
                search: v,
                status: _statusFilter == 'ALL' ? null : _statusFilter,
                refresh: true,
              ),
            );
          },
          onChanged: (_) => setState(() {}),
          onTap: () => setState(() => _isSearchFocused = true),
          onEditingComplete: () => setState(() => _isSearchFocused = false),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          BookingStatusChip(
            status: 'ALL',
            isSelected: _statusFilter == 'ALL',
            onTap: () => _applyFilter('ALL'),
          ),
          const SizedBox(width: 8),
          BookingStatusChip(
            status: 'CONFIRMED',
            isSelected: _statusFilter == 'CONFIRMED',
            onTap: () => _applyFilter('CONFIRMED'),
          ),
          const SizedBox(width: 8),
          BookingStatusChip(
            status: 'TENTATIVE',
            isSelected: _statusFilter == 'TENTATIVE',
            onTap: () => _applyFilter('TENTATIVE'),
          ),
          const SizedBox(width: 8),
          BookingStatusChip(
            status: 'IN_PROGRESS',
            isSelected: _statusFilter == 'IN_PROGRESS',
            onTap: () => _applyFilter('IN_PROGRESS'),
          ),
          const SizedBox(width: 8),
          BookingStatusChip(
            status: 'COMPLETED',
            isSelected: _statusFilter == 'COMPLETED',
            onTap: () => _applyFilter('COMPLETED'),
          ),
          const SizedBox(width: 8),
          BookingStatusChip(
            status: 'CANCELLED',
            isSelected: _statusFilter == 'CANCELLED',
            onTap: () => _applyFilter('CANCELLED'),
          ),
        ],
      ),
    );
  }

  void _applyFilter(String status) {
    HapticFeedback.selectionClick();
    setState(() => _statusFilter = status);
    context.read<BookingBloc>().add(
      LoadBookings(
        status: status == 'ALL' ? null : status,
        refresh: true,
      ),
    );
  }

  Widget _buildBookingList(BookingsLoaded state) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        context.read<BookingBloc>().add(
          const LoadBookings(refresh: true),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 24 : 16,
              vertical: 8,
            ),
            itemCount: state.bookings.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.bookings.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              }
              final booking = state.bookings[index];
              return _buildBookingItem(booking, isWide);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingItem(dynamic booking, bool isWide) {
    final initials = booking.customerName.isNotEmpty
        ? booking.customerName[0].toUpperCase()
        : '?';
    final statusInfo = BookingStatusHelper.getInfo(booking.status, Theme.of(context).colorScheme);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
        child: InkWell(
          onTap: () => context.push('/bookings/${booking.id}'),
          borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
          child: Container(
            padding: EdgeInsets.all(isWide ? 20 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                _buildAvatar(booking, initials, statusInfo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName,
                        style: DesignSystem.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.tag_rounded,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking.bookingNumber,
                            style: DesignSystem.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.category_outlined,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              Formatters.capitalize(booking.eventType),
                              style: DesignSystem.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking.eventDate,
                            style: DesignSystem.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(booking.totalAmount),
                      style: DesignSystem.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    BookingStatusBadge(status: booking.status, compact: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
    dynamic booking,
    String initials,
    BookingStatusInfo statusInfo,
  ) {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusInfo.color,
                statusInfo.color.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
          ),
          child: Center(
            child: Text(
              initials,
              style: DesignSystem.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: statusInfo.backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surface,
                width: 2,
              ),
            ),
            child: Icon(
              statusInfo.icon,
              size: 10,
              color: statusInfo.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    if (_statusFilter != 'ALL') {
      final statusInfo = BookingStatusHelper.getInfo(_statusFilter, Theme.of(context).colorScheme);
      return EventFlowEmptyState(
        icon: statusInfo.icon,
        title: 'No ${statusInfo.label.toLowerCase()} bookings',
        subtitle: 'There are no bookings with this status',
        actionLabel: 'Clear filter',
        onAction: () => _applyFilter('ALL'),
      );
    }
    if (_searchController.text.isNotEmpty) {
      return EventFlowEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        subtitle: 'Try adjusting your search terms',
        actionLabel: 'Clear search',
        onAction: () {
          _searchController.clear();
          context.read<BookingBloc>().add(const LoadBookings(refresh: true));
        },
      );
    }
    return EventFlowEmptyState(
      icon: Icons.calendar_today_rounded,
      title: 'No bookings yet',
      subtitle: 'Create your first booking to get started',
      actionLabel: 'Create booking',
      onAction: () {
        if (_isGuest) {
          _showLoginRequired(context);
        } else {
          context.push('/bookings/new');
        }
      },
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.ivory,
      highlightColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 16,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 24,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  void _showLoginRequired(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignSystem.radiusXl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in required',
              style: DesignSystem.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to create and manage bookings',
              style: DesignSystem.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/login');
                },
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Sign in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
