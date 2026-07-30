import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/core/widgets/premium_search_bar.dart';
import 'package:eventflow_app/core/widgets/premium_card.dart';
import 'package:eventflow_app/core/widgets/premium_avatar.dart';
import 'package:eventflow_app/core/widgets/premium_animated_widgets.dart';
import 'package:eventflow_app/core/widgets/status_chip.dart';
import 'package:eventflow_app/core/widgets/empty_state_widget.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/loading_widget.dart';
import 'package:eventflow_app/core/widgets/demo_banner.dart';
import 'package:eventflow_app/core/widgets/login_required_sheet.dart';
import 'package:eventflow_app/core/widgets/swipe_action_wrapper.dart';
import 'package:eventflow_app/core/widgets/enhanced_search_sheet.dart';
import 'package:eventflow_app/features/bookings/presentation/bloc/booking_bloc.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

class BookingListPage extends StatefulWidget {
  const BookingListPage({super.key});

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  final _searchController = TextEditingController();
  String? _statusFilter;
  final _scrollController = ScrollController();
  Map<String, dynamic> _activeFilters = {};

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
            status: _statusFilter,
          ),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return AppColors.bookingConfirmed;
      case 'TENTATIVE':
        return AppColors.bookingTentative;
      case 'COMPLETED':
        return AppColors.bookingCompleted;
      case 'CANCELLED':
        return AppColors.bookingCancelled;
      case 'IN_PROGRESS':
        return AppColors.bookingInProgress;
      default:
        return AppColors.bookingDraft;
    }
  }

  LinearGradient _avatarGradient(String status) {
    switch (status) {
      case 'CONFIRMED':
        return AppColors.successGradient;
      case 'TENTATIVE':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'IN_PROGRESS':
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'COMPLETED':
        return const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'CANCELLED':
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppColors.primaryGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Bookings',
          style: TextStyle(
            fontSize: AppDimens.fontXxl,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimens.md),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthGuestAuthenticated) {
                    showLoginRequiredSheet(context);
                  } else {
                    context.push('/bookings/new');
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const DemoBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.lg,
              AppDimens.sm,
              AppDimens.lg,
              AppDimens.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: PremiumSearchBar(
                    controller: _searchController,
                    hintText: 'Search bookings...',
                    onSubmitted: (v) => context.read<BookingBloc>().add(
                      LoadBookings(search: v, refresh: true),
                    ),
                    onClear: () => context.read<BookingBloc>().add(
                      const LoadBookings(refresh: true),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.sm),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.textTertiary,
                          size: 20,
                        ),
                        onPressed: _openFilterSheet,
                      ),
                    ),
                    if (_activeFilters.isNotEmpty)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${_activeFilters.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: AppDimens.chipHeight + 8,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
              children: [
                _buildFilterChip('All', null),
                _buildFilterChip('Confirmed', 'CONFIRMED'),
                _buildFilterChip('Tentative', 'TENTATIVE'),
                _buildFilterChip('In Progress', 'IN_PROGRESS'),
                _buildFilterChip('Completed', 'COMPLETED'),
                _buildFilterChip('Cancelled', 'CANCELLED'),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.xs),
          Expanded(
            child: BlocBuilder<BookingBloc, BookingState>(
              builder: (context, state) {
                if (state is BookingsLoading) {
                  return const ShimmerList();
                }
                if (state is BookingDetailLoaded ||
                    state is BookingActionSuccess) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (state is BookingError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: () =>
                        context.read<BookingBloc>().add(const LoadBookings()),
                  );
                }
                if (state is BookingsLoaded) {
                  if (state.bookings.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.event_busy_rounded,
                      title: 'No bookings found',
                      subtitle: 'Create your first booking to get started',
                      tips: [
                        'Tap the + button to create a new booking',
                        'Use filters to narrow down results',
                        'Pull down to refresh the list',
                      ],
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async {
                      context.read<BookingBloc>().add(
                        const LoadBookings(refresh: true),
                      );
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.lg,
                        vertical: AppDimens.sm,
                      ),
                      itemCount:
                          state.bookings.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.bookings.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppDimens.lg),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        }
                        final booking = state.bookings[index];
                        return StaggeredListItem(
                          index: index,
                          totalCount: state.bookings.length,
                          child: _buildBookingItem(booking),
                        );
                      },
                    ),
                  );
                }
                return const ShimmerList();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openFilterSheet() {
    EnhancedSearchSheet.show(
      context,
      currentFilters: _activeFilters,
      onApply: (filters) {
        setState(() => _activeFilters = filters);
        context.read<BookingBloc>().add(
          LoadBookings(
            search: filters['search'] as String?,
            status: filters['status'] as String?,
            refresh: true,
          ),
        );
      },
      onClear: () {
        setState(() => _activeFilters = {});
        context.read<BookingBloc>().add(const LoadBookings(refresh: true));
      },
    );
  }

  Widget _buildBookingItem(dynamic booking) {
    final statusColor = _statusColor(booking.status);
    final initials = booking.customerName.isNotEmpty
        ? booking.customerName[0].toUpperCase()
        : '?';
    final authState = context.read<AuthBloc>().state;
    final isGuest = authState is AuthGuestAuthenticated;

    return SwipeActionWrapper(
      key: ValueKey(booking.id),
      confirmDelete: !isGuest,
      onDismissed: isGuest
          ? null
          : () {
              if (booking.status == 'CONFIRMED' ||
                  booking.status == 'TENTATIVE') {
                context.read<BookingBloc>().add(
                  MarkBookingCompleted(id: booking.id),
                );
              } else if (booking.status == 'IN_PROGRESS') {
                context.read<BookingBloc>().add(
                  MarkBookingCompleted(id: booking.id),
                );
              }
            },
      confirmDismiss: isGuest
          ? (_) async {
              showLoginRequiredSheet(context);
              return false;
            }
          : (_) async {
              if (booking.status == 'CONFIRMED' ||
                  booking.status == 'TENTATIVE') {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Complete Booking'),
                    content: const Text('Mark this booking as completed?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Complete'),
                      ),
                    ],
                  ),
                );
              }
              return false;
            },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.sm),
        child: PremiumCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppDimens.lg),
          onTap: () => context.push('/bookings/${booking.id}'),
          child: Row(
            children: [
              GradientAvatar(
                initials: initials,
                radius: AppDimens.avatarMd / 2,
                gradient: _avatarGradient(booking.status),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
                      style: const TextStyle(
                        fontSize: AppDimens.fontBase,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimens.xs),
                    Text(
                      '${booking.bookingNumber} · ${Formatters.capitalize(booking.eventType)}',
                      style: const TextStyle(
                        fontSize: AppDimens.fontSm,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.eventDate,
                      style: const TextStyle(
                        fontSize: AppDimens.fontXs,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(booking.totalAmount),
                    style: const TextStyle(
                      fontSize: AppDimens.fontMd,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: AppDimens.xs),
                  StatusChip(
                    label: Formatters.statusLabel(booking.status),
                    color: statusColor,
                    small: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.sm),
      child: AnimatedContainer(
        duration: AppDimens.animNormal,
        curve: AppDimens.curveDefault,
        child: FilterChip(
          label: AnimatedDefaultTextStyle(
            duration: AppDimens.animNormal,
            style: TextStyle(
              fontSize: AppDimens.fontSm,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            child: Text(label),
          ),
          selected: isSelected,
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.sm,
            vertical: 0,
          ),
          onSelected: (selected) {
            setState(() => _statusFilter = selected ? status : null);
            context.read<BookingBloc>().add(
              LoadBookings(status: _statusFilter, refresh: true),
            );
          },
        ),
      ),
    );
  }
}
