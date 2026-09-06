import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/design_system.dart';

class EventFlowSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? leadingIcon;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;

  const EventFlowSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.leadingIcon,
    this.padding,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: DesignSystem.spacing4,
            vertical: DesignSystem.spacing2,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: DesignSystem.iconMd,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: DesignSystem.spacing2),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DesignSystem.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: DesignSystem.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacing2,
                      vertical: DesignSystem.spacing1,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel!,
                    style: DesignSystem.labelLarge.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          if (showDivider) ...[
            const SizedBox(height: DesignSystem.spacing2),
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outlineVariant,
            ),
          ],
        ],
      ),
    );
  }
}
