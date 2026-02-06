import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/direct_message.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Admin page for viewing private direct messages from users
class AdminMessagesPage extends ConsumerStatefulWidget {
  const AdminMessagesPage({super.key});

  @override
  ConsumerState<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends ConsumerState<AdminMessagesPage> {
  MessageCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final messageRepo = ref.read(directMessageRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Messages'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textWhite,
        actions: [
          // Mark all as read
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await messageRepo.markAllAsRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All messages marked as read')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          _buildFilterChips(),
          // Messages list
          Expanded(
            child: StreamBuilder<List<DirectMessageModel>>(
              stream: _selectedCategory != null
                  ? messageRepo.streamByCategory(_selectedCategory!)
                  : messageRepo.streamAllMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageCard(messages[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _selectedCategory == null,
              onSelected: (selected) {
                setState(() => _selectedCategory = null);
              },
              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 8),
            ...MessageCategory.values.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category.displayName),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                  },
                  selectedColor: _getCategoryColor(category).withValues(alpha: 0.2),
                  avatar: Icon(
                    _getCategoryIcon(category),
                    size: 16,
                    color: _selectedCategory == category
                        ? _getCategoryColor(category)
                        : AppTheme.textMedium,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCategory != null
                ? 'No ${_selectedCategory!.displayName.toLowerCase()} messages'
                : 'No messages yet',
            style: AppTheme.body(color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(DirectMessageModel message) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final categoryColor = _getCategoryColor(message.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: message.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
        side: BorderSide(
          color: message.isRead
              ? Colors.transparent
              : categoryColor.withValues(alpha: 0.5),
          width: message.isRead ? 0 : 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showMessageDetail(message),
        borderRadius: AppTheme.borderRadiusMedium,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Category badge + timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(message.category),
                          size: 14,
                          color: categoryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          message.category.displayName,
                          style: AppTheme.caption(
                            size: 11,
                            color: categoryColor,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status and timestamp
                  Row(
                    children: [
                      if (!message.isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'NEW',
                            style: AppTheme.caption(
                              size: 9,
                              color: AppTheme.textWhite,
                              weight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        dateFormat.format(message.timestamp),
                        style: AppTheme.caption(
                          size: 11,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // User info row
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                    backgroundImage: message.profilePic != null
                        ? AssetImage('lib/assets/images/${message.profilePic}')
                        : null,
                    child: message.profilePic == null
                        ? Icon(
                            Icons.person,
                            size: 18,
                            color: AppTheme.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  // Username and email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.username,
                          style: AppTheme.body(
                            weight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          message.userEmail,
                          style: AppTheme.caption(
                            size: 11,
                            color: AppTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Time
                  Text(
                    timeFormat.format(message.timestamp),
                    style: AppTheme.caption(
                      size: 11,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Message preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.messagePreview,
                  style: AppTheme.body(
                    size: 14,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageDetail(DirectMessageModel message) {
    final messageRepo = ref.read(directMessageRepositoryProvider);
    final dateFormat = DateFormat('MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final categoryColor = _getCategoryColor(message.category);

    // Mark as read when viewing
    if (!message.isRead) {
      messageRepo.markAsRead(message.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Category badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getCategoryIcon(message.category),
                                    size: 18,
                                    color: categoryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    message.category.displayName,
                                    style: AppTheme.body(
                                      weight: FontWeight.w600,
                                      color: categoryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Delete button
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: AppTheme.error,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _confirmDelete(message);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // User info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  AppTheme.primary.withValues(alpha: 0.2),
                              backgroundImage: message.profilePic != null
                                  ? AssetImage(
                                      'lib/assets/images/${message.profilePic}')
                                  : null,
                              child: message.profilePic == null
                                  ? Icon(
                                      Icons.person,
                                      size: 24,
                                      color: AppTheme.primary,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.username,
                                    style: AppTheme.title(
                                      size: 18,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  Text(
                                    message.userEmail,
                                    style: AppTheme.body(
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Timestamp
                        Text(
                          '${dateFormat.format(message.timestamp)} at ${timeFormat.format(message.timestamp)}',
                          style: AppTheme.caption(
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),
                        // Full message
                        Text(
                          'Message',
                          style: AppTheme.body(
                            weight: FontWeight.w600,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.message,
                            style: AppTheme.body(
                              size: 15,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(DirectMessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message?'),
        content: Text(
          'Are you sure you want to delete this message from ${message.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(directMessageRepositoryProvider)
                  .deleteMessage(message.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message deleted')),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(MessageCategory category) {
    switch (category) {
      case MessageCategory.bug:
        return AppTheme.error;
      case MessageCategory.question:
        return AppTheme.info;
      case MessageCategory.feature:
        return AppTheme.success;
      case MessageCategory.other:
        return AppTheme.textMedium;
    }
  }

  IconData _getCategoryIcon(MessageCategory category) {
    switch (category) {
      case MessageCategory.bug:
        return Icons.bug_report;
      case MessageCategory.question:
        return Icons.help_outline;
      case MessageCategory.feature:
        return Icons.lightbulb_outline;
      case MessageCategory.other:
        return Icons.chat_bubble_outline;
    }
  }
}
