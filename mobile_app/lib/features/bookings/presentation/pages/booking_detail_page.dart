import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/core/widgets/components/eventflow_card.dart';
import 'package:eventflow_app/core/widgets/components/eventflow_button.dart';
import 'package:eventflow_app/core/widgets/components/eventflow_section_header.dart';
import 'package:eventflow_app/core/widgets/components/eventflow_error_state.dart';
import 'package:eventflow_app/core/widgets/components/eventflow_text_field.dart';
import 'package:eventflow_app/features/bookings/presentation/bloc/booking_bloc.dart';
import 'package:eventflow_app/features/bookings/presentation/widgets/booking_status_widgets.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

class BookingDetailPage extends StatefulWidget {
  final int id;
  const BookingDetailPage({super.key, required this.id});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    context.read<BookingBloc>().add(LoadBookingDetail(id: widget.id));
    _animationController = AnimationController(
      vsync: this,
      duration: DesignSystem.durationSlow,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: DesignSystem.easeEmphasizedDecelerate,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isGuest => context.read<AuthBloc>().state is AuthGuestAuthenticated;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: DesignSystem.spacing2),
                  Expanded(
                    child: Text(
                      state.message,
                      style: DesignSystem.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: DesignSystem.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
              ),
            ),
          );
          context.read<BookingBloc>().add(LoadBookingDetail(id: widget.id));
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: Text(
            'Booking Detail',
            style: DesignSystem.headlineSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(DesignSystem.spacing2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
              ),
              onSelected: (value) {
                if (_isGuest) {
                  _showLoginRequired(context);
                  return;
                }
                switch (value) {
                  case 'edit':
                    context.push('/bookings/${widget.id}/edit');
                    break;
                  case 'confirm':
                    HapticFeedback.mediumImpact();
                    context
                        .read<BookingBloc>()
                        .add(ConfirmBooking(id: widget.id));
                    break;
                  case 'cancel':
                    _showCancelDialog(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: DesignSystem.spacing3),
                      Text(
                        'Edit',
                        style: DesignSystem.bodyMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'confirm',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: DesignSystem.success),
                      const SizedBox(width: DesignSystem.spacing3),
                      Text(
                        'Confirm',
                        style: DesignSystem.bodyMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 18, color: colorScheme.error),
                      const SizedBox(width: DesignSystem.spacing3),
                      Text(
                        'Cancel',
                        style: DesignSystem.bodyMedium.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: DesignSystem.spacing2),
          ],
        ),
        body: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingsLoading) {
              return _buildDetailSkeleton(colorScheme);
            }
            if (state is BookingDetailLoaded) {
              final booking = state.booking;
              return RefreshIndicator(
                color: colorScheme.primary,
                backgroundColor: colorScheme.surface,
                onRefresh: () async {
                  context
                      .read<BookingBloc>()
                      .add(LoadBookingDetail(id: widget.id));
                },
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? DesignSystem.spacing8 : 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusHeader(booking, colorScheme),
                              const SizedBox(height: DesignSystem.spacing4),
                              _buildStatusTimeline(booking, colorScheme),
                              const SizedBox(height: DesignSystem.spacing4),
                              if (isWide)
                                _buildWideLayout(booking, colorScheme)
                              else
                                _buildCompactLayout(booking, colorScheme),
                              const SizedBox(height: DesignSystem.spacing6),
                              _buildActionButtons(booking, colorScheme),
                              const SizedBox(height: DesignSystem.spacing10),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            if (state is BookingError) {
              return EventFlowErrorState.generic(
                onRetry: () => context
                    .read<BookingBloc>()
                    .add(LoadBookingDetail(id: widget.id)),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildStatusHeader(dynamic booking, ColorScheme colorScheme) {
    final statusInfo = BookingStatusHelper.getInfo(booking.status, colorScheme);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(DesignSystem.spacing4, 0, DesignSystem.spacing4, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusInfo.color,
            statusInfo.color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusXl),
        boxShadow: [
          BoxShadow(
            color: statusInfo.color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(DesignSystem.spacing6),
      child: Column(
        children: [
          BookingStatusBadge(
            status: booking.status,
            showIcon: true,
            showLabel: true,
          ),
          const SizedBox(height: DesignSystem.spacing3),
          Text(
            booking.bookingNumber,
            style: DesignSystem.titleMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: DesignSystem.spacing1),
          Text(
            Formatters.currency(booking.totalAmount),
            style: DesignSystem.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(dynamic booking, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
      child: BookingStatusTimeline(currentStatus: booking.status),
    );
  }

  Widget _buildCompactLayout(dynamic booking, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildCustomerSection(booking, colorScheme),
        const SizedBox(height: DesignSystem.spacing3),
        _buildEventDetailsSection(booking, colorScheme),
        const SizedBox(height: DesignSystem.spacing3),
        _buildPaymentSection(booking, colorScheme),
        if (booking.remarks != null && booking.remarks!.isNotEmpty) ...[
          const SizedBox(height: DesignSystem.spacing3),
          _buildRemarksSection(booking, colorScheme),
        ],
      ],
    );
  }

  Widget _buildWideLayout(dynamic booking, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildCustomerSection(booking, colorScheme),
              const SizedBox(height: DesignSystem.spacing3),
              _buildRemarksSection(booking, colorScheme),
            ],
          ),
        ),
        const SizedBox(width: DesignSystem.spacing4),
        Expanded(
          child: Column(
            children: [
              _buildEventDetailsSection(booking, colorScheme),
              const SizedBox(height: DesignSystem.spacing3),
              _buildPaymentSection(booking, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSection(dynamic booking, ColorScheme colorScheme) {
    final initials = booking.customerName.isNotEmpty
        ? booking.customerName[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
      child: EventFlowCard(
        padding: const EdgeInsets.all(DesignSystem.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventFlowSectionHeader(
              title: 'Customer',
              leadingIcon: Icons.person_outline_rounded,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: DesignSystem.spacing3),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: DesignSystem.primaryGradient,
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
                const SizedBox(width: DesignSystem.spacing3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName,
                        style: DesignSystem.bodyLarge.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.tag_rounded, size: 12, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'ID: ${booking.customer}',
                            style: DesignSystem.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetailsSection(dynamic booking, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
      child: EventFlowCard(
        padding: const EdgeInsets.all(DesignSystem.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventFlowSectionHeader(
              title: 'Event Details',
              leadingIcon: Icons.event_outlined,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: DesignSystem.spacing3),
            _detailRow(
              Icons.category_outlined,
              'Event Type',
              Formatters.capitalize(booking.eventType),
              colorScheme,
            ),
            Divider(height: DesignSystem.spacing5, color: colorScheme.outlineVariant),
            _detailRow(
              Icons.calendar_today_rounded,
              'Event Date',
              booking.eventDate,
              colorScheme,
            ),
            Divider(height: DesignSystem.spacing5, color: colorScheme.outlineVariant),
            _detailRow(
              Icons.people_outline_rounded,
              'Guest Count',
              booking.guestCount.toString(),
              colorScheme,
            ),
            if (booking.venueName != null) ...[
              Divider(height: DesignSystem.spacing5, color: colorScheme.outlineVariant),
              _detailRow(
                Icons.location_city_outlined,
                'Venue',
                booking.venueName!,
                colorScheme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(dynamic booking, ColorScheme colorScheme) {
    final balance = booking.totalAmount - booking.advanceAmount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
      child: EventFlowCard(
        padding: const EdgeInsets.all(DesignSystem.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventFlowSectionHeader(
              title: 'Payment',
              leadingIcon: Icons.payments_outlined,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: DesignSystem.spacing3),
            _detailRow(
              Icons.currency_rupee_rounded,
              'Total Amount',
              Formatters.currency(booking.totalAmount),
              colorScheme,
              isHighlighted: true,
            ),
            Divider(height: DesignSystem.spacing5, color: colorScheme.outlineVariant),
            _detailRow(
              Icons.account_balance_wallet_outlined,
              'Advance Paid',
              Formatters.currency(booking.advanceAmount),
              colorScheme,
            ),
            Divider(height: DesignSystem.spacing5, color: colorScheme.outlineVariant),
            _detailRow(
              Icons.receipt_long_outlined,
              'Balance',
              Formatters.currency(balance),
              colorScheme,
              isHighlighted: balance > 0,
              highlightColor: balance > 0 ? DesignSystem.warning : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksSection(dynamic booking, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
      child: EventFlowCard(
        padding: const EdgeInsets.all(DesignSystem.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventFlowSectionHeader(
              title: 'Remarks',
              leadingIcon: Icons.notes_rounded,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: DesignSystem.spacing3),
            Text(
              booking.remarks!,
              style: DesignSystem.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme, {
    bool isHighlighted = false,
    Color? highlightColor,
  }) {
    final valueColor = highlightColor ?? colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignSystem.spacing1),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignSystem.spacing2),
          Expanded(
            child: Text(
              label,
              style: DesignSystem.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: DesignSystem.bodyMedium.copyWith(
              color: valueColor,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic booking, ColorScheme colorScheme) {
    final isGuest = _isGuest;
    final isActive = booking.status != 'COMPLETED' && booking.status != 'CANCELLED';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
      child: Column(
        children: [
          if (booking.status == 'TENTATIVE' || booking.status == 'DRAFT')
            EventFlowButton.filled(
              label: 'Confirm Booking',
              icon: Icons.check_circle_outline_rounded,
              isExpanded: true,
              size: EventFlowButtonSize.large,
              onPressed: isGuest
                  ? () => _showLoginRequired(context)
                  : () {
                      HapticFeedback.mediumImpact();
                      context
                          .read<BookingBloc>()
                          .add(ConfirmBooking(id: widget.id));
                    },
            ),
          if (booking.status == 'CONFIRMED')
            EventFlowButton.filled(
              label: 'Mark In Progress',
              icon: Icons.play_circle_outline_rounded,
              isExpanded: true,
              size: EventFlowButtonSize.large,
              onPressed: isGuest
                  ? () => _showLoginRequired(context)
                  : () {
                      HapticFeedback.mediumImpact();
                      context
                          .read<BookingBloc>()
                          .add(MarkBookingInProgress(id: widget.id));
                    },
            ),
          if (booking.status == 'IN_PROGRESS')
            EventFlowButton.filled(
              label: 'Mark Completed',
              icon: Icons.task_alt_rounded,
              isExpanded: true,
              size: EventFlowButtonSize.large,
              onPressed: isGuest
                  ? () => _showLoginRequired(context)
                  : () {
                      HapticFeedback.mediumImpact();
                      context
                          .read<BookingBloc>()
                          .add(MarkBookingCompleted(id: widget.id));
                    },
            ),
          if (isActive) ...[
            const SizedBox(height: DesignSystem.spacing3),
            EventFlowButton.outlined(
              label: 'Cancel Booking',
              icon: Icons.cancel_outlined,
              isExpanded: true,
              size: EventFlowButtonSize.large,
              foregroundColor: colorScheme.error,
              onPressed: isGuest
                  ? () => _showLoginRequired(context)
                  : () => _showCancelDialog(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSkeleton(ColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerLowest,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 200,
              margin: const EdgeInsets.all(DesignSystem.spacing4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignSystem.radiusXl),
              ),
            ),
            Container(
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
              ),
            ),
            const SizedBox(height: DesignSystem.spacing4),
            ...List.generate(3, (index) => Container(
              height: 120,
              margin: const EdgeInsets.symmetric(
                horizontal: DesignSystem.spacing4,
                vertical: DesignSystem.spacing2,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    if (_isGuest) {
      _showLoginRequired(context);
      return;
    }
    final colorScheme = Theme.of(context).colorScheme;
    final remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusXl),
        ),
        icon: Icon(
          Icons.cancel_outlined,
          color: colorScheme.error,
          size: 32,
        ),
        title: Text(
          'Cancel Booking',
          style: DesignSystem.titleLarge.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this booking? This action cannot be undone.',
              style: DesignSystem.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignSystem.spacing3),
            EventFlowTextField(
              controller: remarksController,
              label: 'Cancellation reason (optional)',
              prefixIcon: Icons.notes_rounded,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Go Back',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              context.read<BookingBloc>().add(CancelBooking(
                id: widget.id,
                remarks: remarksController.text,
              ));
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
              ),
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  void _showLoginRequired(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignSystem.radiusXl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(DesignSystem.spacing6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
              ),
            ),
            const SizedBox(height: DesignSystem.spacing4),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: DesignSystem.spacing4),
            Text(
              'Sign in required',
              style: DesignSystem.titleLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: DesignSystem.spacing2),
            Text(
              'Sign in to manage bookings',
              style: DesignSystem.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignSystem.spacing5),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/login');
                },
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Sign in'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignSystem.spacing3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignSystem.spacing3),
          ],
        ),
      ),
    );
  }
}
