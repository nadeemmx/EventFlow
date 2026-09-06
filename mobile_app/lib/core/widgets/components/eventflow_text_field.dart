import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eventflow_app/core/theme/design_system.dart';

class EventFlowTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? error;
  final String? helperText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final List<TextInputFormatter>? inputFormatters;
  final String? autofillHints;
  final EdgeInsetsGeometry? contentPadding;

  const EventFlowTextField({
    super.key,
    this.label,
    this.hint,
    this.error,
    this.helperText,
    this.controller,
    this.onChanged,
    this.onEditingComplete,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.inputFormatters,
    this.autofillHints,
    this.contentPadding,
  });

  @override
  State<EventFlowTextField> createState() => _EventFlowTextFieldState();
}

class _EventFlowTextFieldState extends State<EventFlowTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasError = widget.error != null && widget.error!.isNotEmpty;

    final borderColor = hasError
        ? colorScheme.error
        : _isFocused
            ? colorScheme.primary
            : colorScheme.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: DesignSystem.durationNormal,
          curve: DesignSystem.easeStandard,
          decoration: BoxDecoration(
            color: widget.enabled
                ? colorScheme.surfaceContainerLowest
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused ? DesignSystem.shadowSm : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            onEditingComplete: widget.onEditingComplete,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            cursorColor: colorScheme.primary,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              helperText: widget.helperText,
              helperMaxLines: 2,
              errorText: widget.error,
              errorMaxLines: 2,
              filled: false,
              contentPadding: widget.contentPadding ??
                  const EdgeInsets.symmetric(
                    horizontal: DesignSystem.textFieldPaddingHorizontal,
                    vertical: 14,
                  ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        widget.prefixIcon,
                        size: DesignSystem.iconMd,
                        color: _isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixIconTap,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12, left: 8),
                        child: Icon(
                          widget.suffixIcon,
                          size: DesignSystem.iconMd,
                          color: _isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              labelStyle: WidgetStateTextStyle.resolveWith((states) {
                final color = states.contains(WidgetState.focused)
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant;
                return DesignSystem.bodyMedium.copyWith(color: color);
              }),
              hintStyle: DesignSystem.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              errorStyle: DesignSystem.bodySmall.copyWith(
                color: colorScheme.error,
              ),
              helperStyle: DesignSystem.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
