import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';
import '../../models/notification_item.dart';
import '../../providers/notifications_provider.dart';

/// Notification inbox (FR14) — matches, claim updates and new messages.
/// Read-only for now: tapping marks a notification as read, but doesn't
/// deep-link to the related post/claim/conversation yet.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _NotificationsBody(provider: notifications),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody({required this.provider});

  final NotificationsProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const LoadingView(message: 'Loading notifications…');
    }
    if (provider.error != null) {
      return ErrorRetryView(message: provider.error!, onRetry: provider.retry);
    }
    if (provider.notifications.isEmpty) {
      return const EmptyView(
        icon: Icons.notifications_none,
        title: 'No notifications yet',
        subtitle: 'Matches, claim updates and messages will show up here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: provider.notifications.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final notification = provider.notifications[index];
        return _NotificationTile(
          notification: notification,
          onTap: () => provider.markAsRead(notification),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationItem notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label:
          '${notification.title}, ${notification.body}'
          '${notification.isRead ? '' : ', unread'}',
      child: ListTile(
        onTap: onTap,
        tileColor: notification.isRead ? null : AppColors.accentSoft.withValues(alpha: 0.4),
        leading: CircleAvatar(
          backgroundColor: AppColors.accentSoft,
          foregroundColor: AppColors.primary,
          child: Icon(_iconFor(notification.type)),
        ),
        title: Text(
          notification.title,
          style: TextStyle(fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600),
        ),
        subtitle: Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(
          _relativeTime(notification.createdAt),
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
        ),
      ),
    );
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.match:
        return Icons.auto_awesome_outlined;
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.claim:
        return Icons.verified_user_outlined;
    }
  }

  String _relativeTime(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) return 'Now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${value.day}/${value.month}';
  }
}
