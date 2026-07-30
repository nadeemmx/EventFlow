import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/core/widgets/premium_card.dart';
import 'package:eventflow_app/core/widgets/premium_avatar.dart';
import 'package:eventflow_app/core/widgets/status_chip.dart';
import 'package:eventflow_app/core/widgets/section_header.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/login_required_sheet.dart';
import 'package:eventflow_app/features/bookings/presentation/bloc/booking_bloc.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

class BookingDetailPage extends StatefulWidget {
  final int id;
  const BookingDetailPage({super.key, required this.id});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<BookingBloc>().add(LoadBookingDetail(id: widget.id));
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

  LinearGradient _statusGradient(String status) {
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

  bool _isGuest(BuildContext context) {
    return context.read<AuthBloc>().state is AuthGuestAuthenticated;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
            ),
          );
          context.read<BookingBloc>().add(LoadBookingDetail(id: widget.id));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'Booking Detail',
            style: TextStyle(
              fontSize: AppDimens.fontXxl,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(AppDimens.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              onSelected: (value) {
                if (_isGuest(context)) {
                  showLoginRequiredSheet(context);
                  return;
                }
                switch (value) {
                  case 'edit':
                    context.push('/bookings/${widget.id}/edit');
                    break;
                  case 'confirm':
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
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'confirm',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                      SizedBox(width: 10),
                      Text('Confirm'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Cancel', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppDimens.sm),
          ],
        ),
        body: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state is BookingDetailLoaded) {
              final booking = state.booking;
              final statusColor = _statusColor(booking.status);
              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: () async {
                  context
                      .read<BookingBloc>()
                      .add(LoadBookingDetail(id: widget.id));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusHeader(booking, statusColor),
                      const SizedBox(height: AppDimens.lg),
                      _buildCustomerSection(booking),
                      const SizedBox(height: AppDimens.md),
                      _buildEventDetailsSection(booking),
                      const SizedBox(height: AppDimens.md),
                      _buildPaymentSection(booking),
                      if (booking.remarks != null &&
                          booking.remarks!.isNotEmpty) ...[
                        const SizedBox(height: AppDimens.md),
                        _buildRemarksSection(booking),
                      ],
                      const SizedBox(height: AppDimens.xxl),
                      _buildActionButtons(booking),
                      const SizedBox(height: AppDimens.huge),
                    ],
                  ),
                ),
              );
            }
            if (state is BookingError) {
              return AppErrorWidget(
                message: state.message,
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

  Widget _buildStatusHeader(dynamic booking, Color statusColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppDimens.lg, 0, AppDimens.lg, 0),
      decoration: BoxDecoration(
        gradient: _statusGradient(booking.status),
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimens.xxl),
      child: Column(
        children: [
          StatusChip(
            label: Formatters.statusLabel(booking.status),
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            showDot: true,
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            booking.bookingNumber,
            style: TextStyle(
              fontSize: AppDimens.fontLg,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppDimens.xs),
          Text(
            Formatters.currency(booking.totalAmount),
            style: const TextStyle(
              fontSize: AppDimens.fontDisplay,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(dynamic booking) {
    final initials = booking.customerName.isNotEmpty
        ? booking.customerName[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: PremiumCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Customer', padding: EdgeInsets.zero),
            const SizedBox(height: AppDimens.sm),
            Row(
              children: [
                GradientAvatar(
                  initials: initials,
                  radius: AppDimens.avatarSm / 2,
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
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${booking.customer}',
                        style: const TextStyle(
                          fontSize: AppDimens.fontSm,
                          color: AppColors.textSecondary,
                        ),
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

  Widget _buildEventDetailsSection(dynamic booking) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: PremiumCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Event Details', padding: EdgeInsets.zero),
            const SizedBox(height: AppDimens.sm),
            _detailRow('Event Type', Formatters.capitalize(booking.eventType)),
            const Divider(height: AppDimens.xxl, color: AppColors.borderLight),
            _detailRow('Event Date', booking.eventDate),
            const Divider(height: AppDimens.xxl, color: AppColors.borderLight),
            _detailRow('Guest Count', booking.guestCount.toString()),
            if (booking.venueName != null) ...[
              const Divider(height: AppDimens.xxl, color: AppColors.borderLight),
              _detailRow('Venue', booking.venueName!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(dynamic booking) {
    final balance = booking.totalAmount - booking.advanceAmount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: PremiumCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Payment', padding: EdgeInsets.zero),
            const SizedBox(height: AppDimens.sm),
            _detailRow('Total Amount', Formatters.currency(booking.totalAmount)),
            const Divider(height: AppDimens.xxl, color: AppColors.borderLight),
            _detailRow('Advance Paid', Formatters.currency(booking.advanceAmount)),
            const Divider(height: AppDimens.xxl, color: AppColors.borderLight),
            _detailRow('Balance', Formatters.currency(balance)),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksSection(dynamic booking) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: PremiumCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Remarks', padding: EdgeInsets.zero),
            const SizedBox(height: AppDimens.sm),
            Text(
              booking.remarks!,
              style: const TextStyle(
                fontSize: AppDimens.fontMd,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(dynamic booking) {
    final isGuest = _isGuest(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: Column(
        children: [
          if (booking.status == 'TENTATIVE' || booking.status == 'DRAFT')
            _premiumButton(
              label: 'Confirm Booking',
              icon: Icons.check_circle_outline_rounded,
              gradient: AppColors.successGradient,
              onPressed: isGuest
                  ? () => showLoginRequiredSheet(context)
                  : () => context
                      .read<BookingBloc>()
                      .add(ConfirmBooking(id: widget.id)),
            ),
          if (booking.status == 'CONFIRMED')
            _premiumButton(
              label: 'Mark In Progress',
              icon: Icons.play_circle_outline_rounded,
              gradient: AppColors.primaryGradient,
              onPressed: isGuest
                  ? () => showLoginRequiredSheet(context)
                  : () => context
                      .read<BookingBloc>()
                      .add(MarkBookingInProgress(id: widget.id)),
            ),
          if (booking.status == 'IN_PROGRESS')
            _premiumButton(
              label: 'Mark Completed',
              icon: Icons.task_alt_rounded,
              gradient: AppColors.successGradient,
              onPressed: isGuest
                  ? () => showLoginRequiredSheet(context)
                  : () => context
                      .read<BookingBloc>()
                      .add(MarkBookingCompleted(id: widget.id)),
            ),
          if (booking.status != 'COMPLETED' &&
              booking.status != 'CANCELLED') ...[
            const SizedBox(height: AppDimens.md),
            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: isGuest
                    ? () => showLoginRequiredSheet(context)
                    : () => _showCancelDialog(context),
                icon: const Icon(Icons.cancel_outlined, size: 20),
                label: const Text(
                  'Cancel Booking',
                  style: TextStyle(
                    fontSize: AppDimens.fontMd,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _premiumButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: AppDimens.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: AppDimens.fontMd,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppDimens.fontMd,
              color: AppColors.textSecondary,
            ),
          ),
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
    );
  }

  void _showCancelDialog(BuildContext context) {
    if (_isGuest(context)) {
      showLoginRequiredSheet(context);
      return;
    }
    final remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.dialogRadius),
        ),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
            SizedBox(width: AppDimens.sm),
            Text(
              'Cancel Booking',
              style: TextStyle(
                fontSize: AppDimens.fontLg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: remarksController,
          decoration: InputDecoration(
            labelText: 'Cancellation reason (optional)',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Go Back',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<BookingBloc>().add(CancelBooking(
                    id: widget.id, remarks: remarksController.text));
              },
              child: const Text(
                'Cancel Booking',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
