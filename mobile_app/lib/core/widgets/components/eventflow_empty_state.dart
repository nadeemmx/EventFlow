import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/design_system.dart';

class EventFlowEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? child;
  final double? iconSize;
  final Color? iconColor;

  const EventFlowEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.child,
    this.iconSize,
    this.iconColor,
  });

  const EventFlowEmptyState.events({
    super.key,
    this.actionLabel,
    this.onAction,
    this.child,
  })  : icon = Icons.event_outlined,
       title = 'No events yet',
       subtitle = 'Create your first event to get started',
       iconSize = null,
       iconColor = null;

  const EventFlowEmptyState.bookings({
    super.key,
    this.actionLabel,
    this.onAction,
    this.child,
  })  : icon = Icons.calendar_today_outlined,
       title = 'No bookings',
       subtitle = 'Your bookings will appear here',
       iconSize = null,
       iconColor = null;

  const EventFlowEmptyState.leads({
    super.key,
    this.actionLabel,
    this.onAction,
    this.child,
  })  : icon = Icons.people_outline,
       title = 'No leads',
       subtitle = 'Add your first lead to start tracking',
       iconSize = null,
       iconColor = null;

  const EventFlowEmptyState.search({
    super.key,
    this.actionLabel,
    this.onAction,
    this.child,
  })  : icon = Icons.search_off,
       title = 'No results',
       subtitle = 'Try adjusting your search terms',
       iconSize = null,
       iconColor = null;

  const EventFlowEmptyState.network({
    super.key,
    this.actionLabel,
    this.onAction,
    this.child,
  })  : icon = Icons.wifi_off,
       title = 'No connection',
       subtitle = 'Check your internet and try again',
       iconSize = null,
       iconColor = null;

  const EventFlowEmptyState.error({
    super.key,
    this.actionLabel,
    this.onAction,
    this.child,
  })  : icon = Icons.error_outline,
       title = 'Something went wrong',
       subtitle = 'Please try again later',
       iconSize = null,
       iconColor = null;

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
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize ?? 40,
                color: iconColor ?? colorScheme.primary,
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignSystem.spacing5),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
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
