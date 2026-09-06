import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eventflow_app/core/theme/design_system.dart';

enum EventFlowButtonVariant { filled, outlined, text, tonal }

enum EventFlowButtonSize { small, medium, large, extraLarge }

class EventFlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EventFlowButtonVariant variant;
  final EventFlowButtonSize size;
  final IconData? icon;
  final bool iconRight;
  final bool isLoading;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? child;

  const EventFlowButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = EventFlowButtonVariant.filled,
    this.size = EventFlowButtonSize.medium,
    this.icon,
    this.iconRight = false,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
    this.child,
  });

  const EventFlowButton.filled({
    super.key,
    required this.label,
    this.onPressed,
    this.size = EventFlowButtonSize.medium,
    this.icon,
    this.iconRight = false,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
    this.child,
  })  : variant = EventFlowButtonVariant.filled;

  const EventFlowButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.size = EventFlowButtonSize.medium,
    this.icon,
    this.iconRight = false,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
    this.child,
  })  : variant = EventFlowButtonVariant.outlined;

  const EventFlowButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.size = EventFlowButtonSize.medium,
    this.icon,
    this.iconRight = false,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
    this.child,
  })  : variant = EventFlowButtonVariant.text;

  const EventFlowButton.tonal({
    super.key,
    required this.label,
    this.onPressed,
    this.size = EventFlowButtonSize.medium,
    this.icon,
    this.iconRight = false,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
    this.child,
  })  : variant = EventFlowButtonVariant.tonal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = onPressed != null && !isLoading;

    final buttonStyle = _getButtonStyle(colorScheme, isEnabled);

    Widget button = switch (variant) {
      EventFlowButtonVariant.filled => FilledButton(
          onPressed: isEnabled ? _handlePressed : null,
          style: buttonStyle,
          child: _buildChild(colorScheme),
        ),
      EventFlowButtonVariant.outlined => OutlinedButton(
          onPressed: isEnabled ? _handlePressed : null,
          style: buttonStyle,
          child: _buildChild(colorScheme),
        ),
      EventFlowButtonVariant.text => TextButton(
          onPressed: isEnabled ? _handlePressed : null,
          style: buttonStyle,
          child: _buildChild(colorScheme),
        ),
      EventFlowButtonVariant.tonal => FilledButton.tonal(
          onPressed: isEnabled ? _handlePressed : null,
          style: buttonStyle,
          child: _buildChild(colorScheme),
        ),
    };

    if (isExpanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  ButtonStyle _getButtonStyle(ColorScheme colorScheme, bool isEnabled) {
    final height = switch (size) {
      EventFlowButtonSize.small => DesignSystem.buttonHeightSmall,
      EventFlowButtonSize.medium => DesignSystem.buttonHeightMedium,
      EventFlowButtonSize.large => DesignSystem.buttonHeightLarge,
      EventFlowButtonSize.extraLarge => DesignSystem.buttonHeightXl,
    };

    final horizontalPadding = switch (size) {
      EventFlowButtonSize.small => 16.0,
      EventFlowButtonSize.medium => 24.0,
      EventFlowButtonSize.large => 28.0,
      EventFlowButtonSize.extraLarge => 32.0,
    };

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
    );

    return ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size(0, height)),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(horizontal: horizontalPadding),
      ),
      shape: WidgetStateProperty.all(shape),
      textStyle: WidgetStateProperty.all(_getTextStyle()),
      backgroundColor: _getBackgroundColor(colorScheme, isEnabled),
      foregroundColor: _getForegroundColor(colorScheme, isEnabled),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.onSurface.withValues(alpha: 0.08);
        }
        return null;
      }),
    );
  }

  WidgetStateProperty<Color?> _getBackgroundColor(ColorScheme colorScheme, bool isEnabled) {
    return WidgetStateProperty.resolveWith((states) {
      if (backgroundColor != null && isEnabled) return backgroundColor;

      if (!isEnabled) {
        return switch (variant) {
          EventFlowButtonVariant.filled => colorScheme.onSurface.withValues(alpha: 0.12),
          EventFlowButtonVariant.outlined => Colors.transparent,
          EventFlowButtonVariant.text => Colors.transparent,
          EventFlowButtonVariant.tonal => colorScheme.onSurface.withValues(alpha: 0.12),
        };
      }

      return switch (variant) {
        EventFlowButtonVariant.filled => colorScheme.primary,
        EventFlowButtonVariant.outlined => Colors.transparent,
        EventFlowButtonVariant.text => Colors.transparent,
        EventFlowButtonVariant.tonal => colorScheme.secondaryContainer,
      };
    });
  }

  WidgetStateProperty<Color?> _getForegroundColor(ColorScheme colorScheme, bool isEnabled) {
    return WidgetStateProperty.resolveWith((states) {
      if (foregroundColor != null && isEnabled) return foregroundColor;

      if (!isEnabled) {
        return colorScheme.onSurface.withValues(alpha: 0.38);
      }

      return switch (variant) {
        EventFlowButtonVariant.filled => colorScheme.onPrimary,
        EventFlowButtonVariant.outlined => colorScheme.primary,
        EventFlowButtonVariant.text => colorScheme.primary,
        EventFlowButtonVariant.tonal => colorScheme.onSecondaryContainer,
      };
    });
  }

  TextStyle _getTextStyle() {
    return switch (size) {
      EventFlowButtonSize.small => DesignSystem.labelMedium,
      EventFlowButtonSize.medium => DesignSystem.labelLarge,
      EventFlowButtonSize.large => DesignSystem.titleSmall,
      EventFlowButtonSize.extraLarge => DesignSystem.titleMedium,
    };
  }

  Widget _buildChild(ColorScheme colorScheme) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == EventFlowButtonVariant.filled
                ? colorScheme.onPrimary
                : colorScheme.primary,
          ),
        ),
      );
    }

    final labelWidget = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    final iconWidget = icon != null ? Icon(icon, size: DesignSystem.buttonIconSize) : child;

    if (icon == null && child == null) return labelWidget;

    final gap = SizedBox(width: DesignSystem.buttonGap);

    if (iconRight) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [labelWidget, gap, iconWidget!],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [iconWidget!, gap, labelWidget],
    );
  }

  void _handlePressed() {
    HapticFeedback.lightImpact();
    onPressed?.call();
  }
}
