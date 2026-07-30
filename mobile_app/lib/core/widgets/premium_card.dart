import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final Border? border;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppDimens.cardRadius,
    this.backgroundColor,
    this.onTap,
    this.boxShadow,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: 'card',
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: AppDimens.lg, vertical: AppDimens.xs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: gradient == null ? (backgroundColor ?? AppColors.surface) : null,
          gradient: gradient,
          border: border ?? Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: boxShadow ?? AppColors.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(AppDimens.lg),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
