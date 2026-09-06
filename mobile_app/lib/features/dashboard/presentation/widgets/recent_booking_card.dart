import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/features/dashboard/data/models/dashboard_model.dart';

class RecentBookingCard extends StatelessWidget {
  final RecentBooking booking;
  final VoidCallback? onTap;

  const RecentBookingCard({super.key, required this.booking, this.onTap});

  Color _statusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'CONFIRMED':
        return DesignSystem.success;
      case 'TENTATIVE':
        return DesignSystem.warning;
      case 'COMPLETED':
        return const Color(0xFF059669);
      case 'CANCELLED':
        return colorScheme.error;
      case 'IN_PROGRESS':
        return DesignSystem.info;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  Color _statusBg(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'CONFIRMED':
        return DesignSystem.successLight;
      case 'TENTATIVE':
        return DesignSystem.warningLight;
      case 'COMPLETED':
        return DesignSystem.successLight;
      case 'CANCELLED':
        return colorScheme.errorContainer;
      case 'IN_PROGRESS':
        return DesignSystem.infoLight;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(booking.status, colorScheme);
    final statusBg = _statusBg(booking.status, colorScheme);
    final initials = booking.customerName.isNotEmpty
        ? booking.customerName.split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSystem.spacing4,
        vertical: DesignSystem.spacing1,
      ),
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap?.call();
                }
              : null,
          borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(DesignSystem.spacing3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: DesignSystem.labelMedium.copyWith(
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
                        style: DesignSystem.bodyMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${booking.bookingNumber}  ·  ${booking.eventDate}',
                        style: DesignSystem.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignSystem.spacing2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(booking.totalAmount),
                      style: DesignSystem.bodyMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignSystem.spacing2,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
                      ),
                      child: Text(
                        Formatters.statusLabel(booking.status),
                        style: DesignSystem.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
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
}
