import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';

class SwipeActionWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onDismissed;
  final Future<bool?> Function(DismissDirection)? confirmDismiss;
  final bool confirmDelete;

  const SwipeActionWrapper({
    super.key,
    required this.child,
    this.onDismissed,
    this.confirmDismiss,
    this.confirmDelete = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key ?? const ValueKey('swipe_action'),
      direction: confirmDelete
          ? DismissDirection.horizontal
          : DismissDirection.startToEnd,
      confirmDismiss: confirmDismiss,
      onDismissed: (_) => onDismissed?.call(),
      background: _buildStartBackground(),
      secondaryBackground: _buildEndBackground(),
      child: child,
    );
  }

  Widget _buildStartBackground() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(bottom: AppDimens.sm),
      padding: const EdgeInsets.only(left: AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(width: 8),
          Text(
            'Confirm',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppDimens.fontSm,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndBackground() {
    return Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.only(bottom: AppDimens.sm),
      padding: const EdgeInsets.only(right: AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppDimens.fontSm,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}
