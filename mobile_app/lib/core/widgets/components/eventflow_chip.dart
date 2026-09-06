import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eventflow_app/core/theme/design_system.dart';

enum EventFlowChipVariant { filter, input, suggestion, assist }

class EventFlowChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final bool isSelected;
  final bool isEnabled;
  final EventFlowChipVariant variant;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? foregroundColor;

  const EventFlowChip({
    super.key,
    required this.label,
    this.onTap,
    this.onDeleted,
    this.icon,
    this.trailingIcon,
    this.onTrailingTap,
    this.isSelected = false,
    this.isEnabled = true,
    this.variant = EventFlowChipVariant.filter,
    this.backgroundColor,
    this.selectedColor,
    this.foregroundColor,
  });

  const EventFlowChip.filter({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.trailingIcon,
    this.onTrailingTap,
    this.isSelected = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.selectedColor,
    this.foregroundColor,
  }) : variant = EventFlowChipVariant.filter,
       onDeleted = null;

  const EventFlowChip.input({
    super.key,
    required this.label,
    this.onDeleted,
    this.icon,
    this.isEnabled = true,
    this.backgroundColor,
    this.foregroundColor,
  })  : variant = EventFlowChipVariant.input,
       onTap = null,
       trailingIcon = null,
       onTrailingTap = null,
       isSelected = false,
       selectedColor = null;

  const EventFlowChip.suggestion({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.isEnabled = true,
    this.backgroundColor,
    this.foregroundColor,
  })  : variant = EventFlowChipVariant.suggestion,
       onDeleted = null,
       trailingIcon = null,
       onTrailingTap = null,
       isSelected = false,
       selectedColor = null;

  const EventFlowChip.assist({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.trailingIcon,
    this.onTrailingTap,
    this.isEnabled = true,
    this.backgroundColor,
    this.foregroundColor,
  })  : variant = EventFlowChipVariant.assist,
       onDeleted = null,
       isSelected = false,
       selectedColor = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final chipBg = _getBackgroundColor(colorScheme);
    final chipFg = _getForegroundColor(colorScheme);

    Widget chip = Container(
      height: DesignSystem.chipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
        border: variant == EventFlowChipVariant.filter ||
                variant == EventFlowChipVariant.input
            ? Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected ? 1.5 : 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: DesignSystem.chipIconSize,
              color: chipFg,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: DesignSystem.labelLarge.copyWith(color: chipFg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onTrailingTap,
              child: Icon(
                trailingIcon,
                size: DesignSystem.chipIconSize,
                color: chipFg,
              ),
            ),
          ],
          if (onDeleted != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDeleted,
              child: Icon(
                Icons.close,
                size: 16,
                color: chipFg.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      chip = GestureDetector(
        onTap: isEnabled
            ? () {
                HapticFeedback.selectionClick();
                onTap?.call();
              }
            : null,
        child: chip,
      );
    }

    return chip;
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (backgroundColor != null) return backgroundColor!;

    return switch (variant) {
      EventFlowChipVariant.filter => isSelected
          ? (selectedColor ?? colorScheme.primaryContainer)
          : colorScheme.surfaceContainerLowest,
      EventFlowChipVariant.input => colorScheme.surfaceContainerLowest,
      EventFlowChipVariant.suggestion => colorScheme.surfaceContainerLow,
      EventFlowChipVariant.assist => colorScheme.surfaceContainerLowest,
    };
  }

  Color _getForegroundColor(ColorScheme colorScheme) {
    if (foregroundColor != null) return foregroundColor!;

    return switch (variant) {
      EventFlowChipVariant.filter => isSelected
          ? colorScheme.onPrimaryContainer
          : colorScheme.onSurfaceVariant,
      EventFlowChipVariant.input => colorScheme.onSurfaceVariant,
      EventFlowChipVariant.suggestion => colorScheme.onSurfaceVariant,
      EventFlowChipVariant.assist => colorScheme.onSurfaceVariant,
    };
  }
}
