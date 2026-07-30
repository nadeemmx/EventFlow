import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final bool small;
  final bool showDot;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.small = false,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? color.withValues(alpha: 0.1);
    final fontSize = small ? AppDimens.fontXs : AppDimens.fontSm;
    final horizontalPad = small ? 8.0 : 10.0;
    final verticalPad = small ? 3.0 : 5.0;
    final dotSize = small ? 5.0 : 6.0;

    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: verticalPad),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: small ? 4 : 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
