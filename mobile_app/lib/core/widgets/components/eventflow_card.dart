import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/design_system.dart';

enum EventFlowCardElevation { none, xs, sm, md, lg }

class EventFlowCard extends StatelessWidget {
  final Widget child;
  final EventFlowCardElevation elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool isOutlined;
  final BorderRadius? borderRadius;

  const EventFlowCard({
    super.key,
    required this.child,
    this.elevation = EventFlowCardElevation.xs,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.isOutlined = false,
    this.borderRadius,
  });

  const EventFlowCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.isOutlined = false,
    this.borderRadius,
  }) : elevation = EventFlowCardElevation.md;

  const EventFlowCard.outlined({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.borderRadius,
  })  : elevation = EventFlowCardElevation.none,
        isOutlined = true;

  const EventFlowCard.filled({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.borderRadius,
  })  : elevation = EventFlowCardElevation.xs,
        isOutlined = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cardShadow = switch (elevation) {
      EventFlowCardElevation.none => null,
      EventFlowCardElevation.xs => DesignSystem.shadowXs,
      EventFlowCardElevation.sm => DesignSystem.shadowSm,
      EventFlowCardElevation.md => DesignSystem.shadowMd,
      EventFlowCardElevation.lg => DesignSystem.shadowLg,
    };

    final cardColor = backgroundColor ??
        (isOutlined ? colorScheme.surface : colorScheme.surfaceContainerLowest);

    Widget card = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: borderRadius ?? BorderRadius.circular(DesignSystem.radiusLg),
        border: isOutlined
            ? Border.all(color: colorScheme.outlineVariant, width: 1)
            : null,
        boxShadow: cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(DesignSystem.cardPadding),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}
