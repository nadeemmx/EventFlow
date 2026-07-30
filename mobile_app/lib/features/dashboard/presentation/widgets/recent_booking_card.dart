import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/core/widgets/status_chip.dart';
import 'package:eventflow_app/core/widgets/premium_avatar.dart';
import 'package:eventflow_app/features/dashboard/data/models/dashboard_model.dart';

class RecentBookingCard extends StatelessWidget {
  final RecentBooking booking;
  final VoidCallback? onTap;

  const RecentBookingCard({super.key, required this.booking, this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'CONFIRMED': return AppColors.bookingConfirmed;
      case 'TENTATIVE': return AppColors.bookingTentative;
      case 'COMPLETED': return AppColors.bookingCompleted;
      case 'CANCELLED': return AppColors.bookingCancelled;
      case 'IN_PROGRESS': return AppColors.bookingInProgress;
      default: return AppColors.bookingDraft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    final initials = booking.customerName.isNotEmpty
        ? booking.customerName.split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.lg, vertical: AppDimens.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Row(
              children: [
                GradientAvatar(
                  initials: initials,
                  radius: AppDimens.avatarMd / 2,
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: AppDimens.fontMd,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimens.xs),
                      Text(
                        '${booking.bookingNumber} · ${booking.eventDate}',
                        style: const TextStyle(
                          fontSize: AppDimens.fontSm,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        fontWeight: FontWeight.w800,
                        fontSize: AppDimens.fontMd,
                        color: AppColors.textPrimary,
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
      ),
    );
  }
}
