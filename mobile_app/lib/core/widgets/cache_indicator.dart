import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';

class CacheIndicator extends StatelessWidget {
  final bool isCached;

  const CacheIndicator({super.key, this.isCached = false});

  @override
  Widget build(BuildContext context) {
    if (!isCached) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sm,
        vertical: AppDimens.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.textTertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.storage_rounded,
            size: 14,
            color: AppColors.textTertiary,
          ),
          SizedBox(width: AppDimens.xs),
          Text(
            'Cached',
            style: TextStyle(
              fontSize: AppDimens.fontXs,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
