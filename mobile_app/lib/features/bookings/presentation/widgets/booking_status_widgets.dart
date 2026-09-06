import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/utils/formatters.dart';

class BookingStatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const BookingStatusInfo({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });
}

class BookingStatusHelper {
  BookingStatusHelper._();

  static BookingStatusInfo getInfo(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'CONFIRMED':
        return BookingStatusInfo(
          label: 'Confirmed',
          icon: Icons.check_circle_outline_rounded,
          color: DesignSystem.success,
          backgroundColor: DesignSystem.successLight,
        );
      case 'TENTATIVE':
        return BookingStatusInfo(
          label: 'Tentative',
          icon: Icons.help_outline_rounded,
          color: DesignSystem.warning,
          backgroundColor: DesignSystem.warningLight,
        );
      case 'IN_PROGRESS':
        return BookingStatusInfo(
          label: 'In Progress',
          icon: Icons.play_circle_outline_rounded,
          color: DesignSystem.info,
          backgroundColor: DesignSystem.infoLight,
        );
      case 'COMPLETED':
        return BookingStatusInfo(
          label: 'Completed',
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF059669),
          backgroundColor: const Color(0xFFD1FAE5),
        );
      case 'CANCELLED':
        return BookingStatusInfo(
          label: 'Cancelled',
          icon: Icons.cancel_outlined,
          color: colorScheme.error,
          backgroundColor: colorScheme.errorContainer,
        );
      case 'DRAFT':
        return BookingStatusInfo(
          label: 'Draft',
          icon: Icons.edit_note_rounded,
          color: colorScheme.onSurfaceVariant,
          backgroundColor: colorScheme.surfaceContainerHighest,
        );
      default:
        return BookingStatusInfo(
          label: Formatters.statusLabel(status),
          icon: Icons.help_outline_rounded,
          color: colorScheme.onSurfaceVariant,
          backgroundColor: colorScheme.surfaceContainerHighest,
        );
    }
  }
}

class BookingStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;
  final bool showIcon;
  final bool showLabel;

  const BookingStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
    this.showIcon = true,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final info = BookingStatusHelper.getInfo(status, colorScheme);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? DesignSystem.spacing2 : DesignSystem.spacing3,
        vertical: compact ? DesignSystem.spacing1 / 2 : DesignSystem.spacing1,
      ),
      decoration: BoxDecoration(
        color: info.backgroundColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              info.icon,
              size: compact ? 14 : 16,
              color: info.color,
            ),
            if (showLabel) SizedBox(width: compact ? 4 : 6),
          ],
          if (showLabel)
            Text(
              info.label,
              style: (compact ? DesignSystem.labelSmall : DesignSystem.labelMedium)
                  .copyWith(
                color: info.color,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class BookingStatusChip extends StatelessWidget {
  final String status;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showCount;
  final int? count;

  const BookingStatusChip({
    super.key,
    required this.status,
    this.isSelected = false,
    this.onTap,
    this.showCount = false,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final info = BookingStatusHelper.getInfo(
      status == 'ALL' ? 'DRAFT' : status,
      colorScheme,
    );

    final chipColor = status == 'ALL'
        ? colorScheme.primary
        : isSelected
            ? info.color
            : colorScheme.onSurfaceVariant;

    final chipBg = status == 'ALL'
        ? (isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerLowest)
        : (isSelected ? info.backgroundColor : colorScheme.surfaceContainerLowest);

    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.selectionClick();
              onTap!.call();
            }
          : null,
      child: AnimatedContainer(
        duration: DesignSystem.durationNormal,
        curve: DesignSystem.easeStandard,
        padding: EdgeInsets.symmetric(
          horizontal: DesignSystem.spacing3,
          vertical: DesignSystem.spacing2,
        ),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
          border: Border.all(
            color: isSelected ? chipColor : colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status == 'ALL' ? Icons.dashboard_rounded : info.icon,
              size: 16,
              color: chipColor,
            ),
            const SizedBox(width: DesignSystem.spacing1),
            Text(
              status == 'ALL' ? 'All' : info.label,
              style: DesignSystem.labelMedium.copyWith(
                color: chipColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (showCount && count != null) ...[
              const SizedBox(width: DesignSystem.spacing1),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
                ),
                child: Text(
                  '$count',
                  style: DesignSystem.labelSmall.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BookingStatusTimeline extends StatelessWidget {
  final String currentStatus;
  final bool compact;

  const BookingStatusTimeline({
    super.key,
    required this.currentStatus,
    this.compact = false,
  });

  static const List<String> _statusOrder = [
    'DRAFT',
    'TENTATIVE',
    'CONFIRMED',
    'IN_PROGRESS',
    'COMPLETED',
  ];

  int _currentIndex(String status) {
    if (status == 'CANCELLED') return -1;
    return _statusOrder.indexOf(status);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentIdx = _currentIndex(currentStatus);
    final isCancelled = currentStatus == 'CANCELLED';

    return Container(
      padding: EdgeInsets.all(compact ? DesignSystem.spacing3 : DesignSystem.spacing4),
      decoration: BoxDecoration(
        color: isCancelled
            ? colorScheme.errorContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
        border: Border.all(
          color: isCancelled ? colorScheme.error.withValues(alpha: 0.3) : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: List.generate(_statusOrder.length, (index) {
          final status = _statusOrder[index];
          final info = BookingStatusHelper.getInfo(status, colorScheme);
          final isActive = index <= currentIdx && !isCancelled;
          final isCurrent = index == currentIdx && !isCancelled;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: DesignSystem.durationSlow,
                        width: compact ? 28 : 36,
                        height: compact ? 28 : 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? info.color : colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: isActive ? info.color : colorScheme.outlineVariant,
                            width: isCurrent ? 2 : 1,
                          ),
                          boxShadow: isCurrent ? [
                            BoxShadow(
                              color: info.color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: Icon(
                          info.icon,
                          size: compact ? 14 : 18,
                          color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: DesignSystem.spacing1),
                        Text(
                          info.label,
                          style: DesignSystem.labelSmall.copyWith(
                            color: isActive ? info.color : colorScheme.onSurfaceVariant,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (index < _statusOrder.length - 1)
                  Container(
                    width: 20,
                    height: 2,
                    color: index < currentIdx
                        ? DesignSystem.success
                        : colorScheme.outlineVariant,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
