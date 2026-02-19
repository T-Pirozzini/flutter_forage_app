import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/app_notification.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page that displays the user's notification history.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.email;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    final notifRepo = ref.read(notificationRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        foregroundColor: AppTheme.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () => notifRepo.markAllAsRead(userId),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: notifRepo.streamNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: AppTheme.textMedium),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: AppTheme.title(size: 16, color: AppTheme.textMedium),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see friend requests, likes,\nand comments here.',
                    textAlign: TextAlign.center,
                    style:
                        AppTheme.caption(size: 13, color: AppTheme.textMedium),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _NotificationTile(
                notification: notif,
                onTap: () => _onNotificationTap(context, ref, notif, userId),
                onDismissed: () =>
                    notifRepo.deleteNotification(userId, notif.id),
              );
            },
          );
        },
      ),
    );
  }

  void _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notif,
    String userId,
  ) {
    // Mark as read
    if (!notif.isRead) {
      ref
          .read(notificationRepositoryProvider)
          .markAsRead(userId, notif.id);
    }

    // Navigate based on type
    switch (notif.type) {
      case NotificationType.friendRequest:
      case NotificationType.friendAccepted:
        // Pop back and let user navigate to friends
        Navigator.pop(context);
        break;
      case NotificationType.postLike:
      case NotificationType.postComment:
        // Pop back for now — could deep-link to post in the future
        Navigator.pop(context);
        break;
      case NotificationType.achievement:
      case NotificationType.levelUp:
        // Informational — just mark as read
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead
              ? Colors.transparent
              : AppTheme.info.withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: _iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: AppTheme.caption(
                          size: 12, color: AppTheme.textMedium),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(notification.createdAt),
                      style: AppTheme.caption(
                          size: 11, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (!notification.isRead)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.friendAccepted:
        return Icons.people;
      case NotificationType.postLike:
        return Icons.favorite;
      case NotificationType.postComment:
        return Icons.comment;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.levelUp:
        return Icons.arrow_circle_up;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case NotificationType.friendRequest:
        return AppTheme.info;
      case NotificationType.friendAccepted:
        return AppTheme.success;
      case NotificationType.postLike:
        return AppTheme.accent;
      case NotificationType.postComment:
        return AppTheme.primary;
      case NotificationType.achievement:
        return AppTheme.secondary;
      case NotificationType.levelUp:
        return AppTheme.accent;
    }
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}
