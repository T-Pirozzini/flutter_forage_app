import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/activity_item.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Tab showing friend activity feed
class ActivityTab extends ConsumerStatefulWidget {
  final String userId;

  const ActivityTab({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab> {
  final dateFormat = DateFormat('MMM dd, yyyy');
  final timeFormat = DateFormat('h:mm a');

  String _getActivityMessage(ActivityItemModel activity) {
    // Use the displayName from the model
    return activity.type.displayName;
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.newMarker:
        return Icons.add_location_alt;
      case ActivityType.bookmark:
        return Icons.bookmark;
      case ActivityType.collection:
        return Icons.folder;
      case ActivityType.friendJoined:
        return Icons.person_add;
      case ActivityType.collectionShared:
        return Icons.share;
      case ActivityType.statusUpdate:
        return Icons.update;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.newMarker:
        return AppTheme.primary;
      case ActivityType.bookmark:
        return AppTheme.secondary;
      case ActivityType.collection:
        return AppTheme.info;
      case ActivityType.friendJoined:
        return AppTheme.success;
      case ActivityType.collectionShared:
        return AppTheme.xp;
      case ActivityType.statusUpdate:
        return AppTheme.textMedium;
    }
  }

  String _getRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return dateFormat.format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityRepo = ref.watch(activityFeedRepositoryProvider);

    return StreamBuilder<List<ActivityItemModel>>(
      stream: activityRepo.streamFeed(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                const SizedBox(height: 12),
                Text(
                  'Error loading activity',
                  style: AppTheme.heading(size: 16, color: AppTheme.textMedium),
                ),
                const SizedBox(height: 4),
                Text(
                  '${snapshot.error}',
                  style: AppTheme.body(size: 12, color: AppTheme.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dynamic_feed, size: 64, color: AppTheme.textLight),
                const SizedBox(height: 16),
                Text(
                  'No activity yet',
                  style: AppTheme.heading(size: 18, color: AppTheme.textMedium),
                ),
                const SizedBox(height: 8),
                Text(
                  'When your friends add markers,\ncreate collections, or earn achievements,\nyou\'ll see their activity here.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body(size: 14, color: AppTheme.textLight),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Trigger a refresh - the stream will automatically update
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityCard(activity);
            },
          ),
        );
      },
    );
  }

  Widget _buildActivityCard(ActivityItemModel activity) {
    final color = _getActivityColor(activity.type);

    return Card(
      elevation: activity.read ? 0 : 1,
      margin: EdgeInsets.zero,
      color: activity.read ? Colors.white : color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
        side: BorderSide(
          color: activity.read
              ? AppTheme.textLight.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusMedium,
        onTap: () {
          // Mark as read and navigate to relevant content
          _markAsRead(activity);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Icon(
                  _getActivityIcon(activity.type),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTheme.body(size: 13, color: AppTheme.textDark),
                        children: [
                          TextSpan(
                            text: activity.actorName,
                            style: AppTheme.heading(size: 13, color: AppTheme.textDark),
                          ),
                          TextSpan(text: ' ${_getActivityMessage(activity)}'),
                        ],
                      ),
                    ),
                    if (activity.targetName != null && activity.targetName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        activity.targetName!,
                        style: AppTheme.caption(size: 12, color: color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _getRelativeTime(activity.createdAt),
                      style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (!activity.read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsRead(ActivityItemModel activity) async {
    if (activity.read) return;

    try {
      final activityRepo = ref.read(activityFeedRepositoryProvider);
      await activityRepo.markAsRead(widget.userId, activity.id);
    } catch (e) {
      // Silently fail - not critical
    }
  }
}
