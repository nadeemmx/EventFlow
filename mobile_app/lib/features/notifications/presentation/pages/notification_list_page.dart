import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/widgets/loading_widget.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/empty_state_widget.dart';
import 'package:eventflow_app/core/widgets/demo_banner.dart';
import 'package:eventflow_app/features/notifications/presentation/bloc/notification_bloc.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const LoadNotifications());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<NotificationBloc>().state;
      if (state is NotificationListLoaded && state.hasMore) {
        context.read<NotificationBloc>().add(
            LoadNotifications(page: state.currentPage + 1));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          const DemoBanner(),
          Expanded(
            child: BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is NotificationLoading) {
                  return const ShimmerList();
                }
                if (state is NotificationError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: () =>
                        context.read<NotificationBloc>().add(const LoadNotifications()),
                  );
                }
                if (state is NotificationListLoaded) {
                  if (state.notifications.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.notifications_none_rounded,
                      title: 'No notifications',
                      subtitle: 'You\'re all caught up!',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<NotificationBloc>()
                          .add(const LoadNotifications(refresh: true));
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.lg,
                        vertical: AppDimens.sm,
                      ),
                      itemCount:
                          state.notifications.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.notifications.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppDimens.lg),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final notification = state.notifications[index];
                        final isUnread = notification.status.toUpperCase() == 'UNREAD';
                        return _NotificationTile(
                          notification: notification,
                          isUnread: isUnread,
                          onTap: isUnread
                              ? () => context
                                  .read<NotificationBloc>()
                                  .add(MarkNotificationRead(id: notification.id))
                              : null,
                        );
                      },
                    ),
                  );
                }
                return const ShimmerList();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final dynamic notification;
  final bool isUnread;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.notification,
    required this.isUnread,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.sm),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.primary.withValues(alpha: 0.03)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isUnread
                        ? AppColors.primaryGradient
                        : LinearGradient(
                            colors: [
                              AppColors.textTertiary,
                              AppColors.textHint,
                            ],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: isUnread
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isUnread
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppDimens.fontBase,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: AppDimens.sm),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppDimens.xs),
                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppDimens.fontSm,
                          color: isUnread
                              ? AppColors.textSecondary
                              : AppColors.textTertiary,
                          height: 1.4,
                        ),
                      ),
                      if (notification.createdAt != null) ...[
                        const SizedBox(height: AppDimens.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              notification.createdAt!,
                              style: const TextStyle(
                                fontSize: AppDimens.fontXs,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
