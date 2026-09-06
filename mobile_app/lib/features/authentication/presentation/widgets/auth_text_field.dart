import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eventflow_app/core/theme/design_system.dart';

class AuthTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? error;
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
  final Widget? suffixIcon;
  final VoidCallback? onSuffixTap;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final String? autofillHint;
  final bool autocorrect;
  final TextCapitalization textCapitalization;

  const AuthTextField({
    super.key,
    this.label,
    this.hint,
    this.error,
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
    this.onSuffixTap,
    this.inputFormatters,
    this.validator,
    this.autofillHint,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _hasError = widget.error != null && widget.error!.isNotEmpty;
  }

  @override
  void didUpdateWidget(AuthTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != oldWidget.error) {
      setState(() {
        _hasError = widget.error != null && widget.error!.isNotEmpty;
      });
    }
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

    final borderColor = _hasError
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
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            onEditingComplete: widget.onEditingComplete,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            obscureText: widget.obscureText,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            autocorrect: widget.autocorrect,
            enableSuggestions: !widget.obscureText,
            style: DesignSystem.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
            cursorColor: colorScheme.primary,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              errorText: widget.error,
              errorMaxLines: 2,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignSystem.textFieldPaddingHorizontal,
                vertical: 16,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: Icon(
                        widget.prefixIcon,
                        size: 22,
                        color: _isFocused
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixTap,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16, left: 12),
                        child: widget.suffixIcon,
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
              hintStyle: DesignSystem.bodyLarge.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              errorStyle: DesignSystem.bodySmall.copyWith(
                color: colorScheme.error,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
