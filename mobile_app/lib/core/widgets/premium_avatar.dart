import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';

class GradientAvatar extends StatelessWidget {
  final String? initials;
  final double radius;
  final Gradient? gradient;
  final Widget? child;
  final Color? textColor;
  final String? heroTag;

  const GradientAvatar({
    super.key,
    this.initials,
    this.radius = AppDimens.avatarMd / 2,
    this.gradient,
    this.child,
    this.textColor,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final avatarContainer = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (gradient != null ? AppColors.primary : AppColors.primary)
                .withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child ??
          Center(
            child: Text(
              initials ?? '?',
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w700,
                color: textColor ?? Colors.white,
              ),
            ),
          ),
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: avatarContainer);
    }
    return avatarContainer;
  }
}

class StatusAvatar extends StatelessWidget {
  final String initials;
  final Color statusColor;
  final double radius;
  final Gradient? gradient;

  const StatusAvatar({
    super.key,
    required this.initials,
    required this.statusColor,
    this.radius = AppDimens.avatarMd / 2,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GradientAvatar(
          initials: initials,
          radius: radius,
          gradient: gradient,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: radius * 0.5,
            height: radius * 0.5,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
