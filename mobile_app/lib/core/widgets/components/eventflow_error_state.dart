import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/design_system.dart';

class EventFlowErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? errorDetails;
  final String retryLabel;
  final VoidCallback? onRetry;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Widget? child;
  final bool showDetails;

  const EventFlowErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.subtitle,
    this.errorDetails,
    this.retryLabel = 'Try again',
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.child,
    this.showDetails = false,
  });

  const EventFlowErrorState.generic({
    super.key,
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.child,
  })  : title = 'Something went wrong',
       subtitle = 'An unexpected error occurred',
       errorDetails = null,
       retryLabel = 'Try again',
       showDetails = false;

  const EventFlowErrorState.network({
    super.key,
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.child,
  })  : title = 'Connection error',
       subtitle = 'Check your internet and try again',
       errorDetails = null,
       retryLabel = 'Retry',
       showDetails = false;

  const EventFlowErrorState.server({
    super.key,
    String? details,
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.child,
  })  : title = 'Server error',
       subtitle = 'We couldn\'t process your request',
       errorDetails = details,
       retryLabel = 'Try again',
       showDetails = details != null;

  const EventFlowErrorState.auth({
    super.key,
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.child,
  })  : title = 'Session expired',
       subtitle = 'Please sign in again',
       errorDetails = null,
       retryLabel = 'Sign in',
       showDetails = false;

  const EventFlowErrorState.permission({
    super.key,
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.child,
  })  : title = 'Access denied',
       subtitle = 'You don\'t have permission for this',
       errorDetails = null,
       retryLabel = 'Go back',
       showDetails = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignSystem.spacing6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: DesignSystem.spacing5),
            Text(
              title,
              style: DesignSystem.titleLarge.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DesignSystem.spacing2),
              Text(
                subtitle!,
                style: DesignSystem.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (showDetails && errorDetails != null) ...[
              const SizedBox(height: DesignSystem.spacing3),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DesignSystem.spacing3),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  errorDetails!,
                  style: DesignSystem.bodySmall.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            const SizedBox(height: DesignSystem.spacing5),
            if (onRetry != null)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(retryLabel),
              ),
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: DesignSystem.spacing3),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ],
            if (child != null) ...[
              const SizedBox(height: DesignSystem.spacing4),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}
