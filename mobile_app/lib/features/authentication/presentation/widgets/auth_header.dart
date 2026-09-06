import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/design_system.dart';

class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const AuthHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: DesignSystem.spacing12),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: DesignSystem.primaryGradient,
            borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
            boxShadow: DesignSystem.shadowMd,
          ),
          child: Icon(
            icon,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: DesignSystem.spacing8),
        Text(
          title,
          style: DesignSystem.headlineLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: DesignSystem.spacing2),
          Text(
            subtitle!,
            style: DesignSystem.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
