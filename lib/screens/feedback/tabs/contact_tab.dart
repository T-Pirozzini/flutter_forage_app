import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/direct_message.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Contact Us tab with private messaging form to admin
class ContactTab extends ConsumerStatefulWidget {
  final String? username;
  final String? userProfilePic;

  const ContactTab({
    super.key,
    this.username,
    this.userProfilePic,
  });

  @override
  ConsumerState<ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends ConsumerState<ContactTab> {
  final _controller = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser!;
  MessageCategory _selectedCategory = MessageCategory.question;
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final message = DirectMessageModel(
        id: '',
        userId: _currentUser.uid,
        userEmail: _currentUser.email!,
        username: widget.username ?? _currentUser.email!.split('@')[0],
        profilePic: widget.userProfilePic,
        category: _selectedCategory,
        message: text,
        timestamp: DateTime.now(),
        status: MessageStatus.pending,
      );

      await ref.read(directMessageRepositoryProvider).sendMessage(message);

      _controller.clear();
      setState(() {
        _selectedCategory = MessageCategory.question;
        _isSending = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent! We\'ll get back to you soon.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryLight.withValues(alpha: 0.15),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Send message form
            _buildMessageForm(),
            const SizedBox(height: 24),
            // My sent messages section
            _buildMyMessagesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.mail_outline, color: AppTheme.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                'Send us a message',
                style: AppTheme.title(
                  size: 18,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your message will be sent privately to our team.',
            style: AppTheme.caption(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 16),
          // Category selector
          Text(
            'Category',
            style: AppTheme.body(
              size: 14,
              weight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MessageCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 16,
                      color: isSelected ? AppTheme.textWhite : _getCategoryColor(category),
                    ),
                    const SizedBox(width: 6),
                    Text(category.displayName),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedCategory = category);
                  }
                },
                selectedColor: _getCategoryColor(category),
                backgroundColor: AppTheme.backgroundLight,
                labelStyle: AppTheme.caption(
                  size: 13,
                  color: isSelected ? AppTheme.textWhite : AppTheme.textDark,
                  weight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Message input
          Text(
            'Message',
            style: AppTheme.body(
              size: 14,
              weight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: _getHintText(_selectedCategory),
              hintStyle: AppTheme.body(
                size: 14,
                color: AppTheme.textLight,
              ),
              filled: true,
              fillColor: AppTheme.backgroundLight,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: AppTheme.body(size: 14, color: AppTheme.textDark),
            maxLines: 5,
            minLines: 3,
          ),
          const SizedBox(height: 16),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Send Message',
                          style: AppTheme.body(
                            weight: FontWeight.w600,
                            color: AppTheme.textWhite,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyMessagesSection() {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: AppTheme.textMedium, size: 20),
            const SizedBox(width: 8),
            Text(
              'My Sent Messages',
              style: AppTheme.body(
                size: 16,
                weight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<DirectMessageModel>>(
          stream: ref
              .read(directMessageRepositoryProvider)
              .streamUserMessages(_currentUser.email!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final messages = snapshot.data ?? [];

            if (messages.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 40,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No messages sent yet',
                        style: AppTheme.body(color: AppTheme.textMedium),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: messages.map((message) {
                final categoryColor = _getCategoryColor(message.category);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.textLight.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIcon(message.category),
                                  size: 12,
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
                          const Spacer(),
                          // Date
                          Text(
                            dateFormat.format(message.timestamp),
                            style: AppTheme.caption(
                              size: 11,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: message.isRead
                                  ? AppTheme.success.withValues(alpha: 0.15)
                                  : AppTheme.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  message.isRead
                                      ? Icons.check_circle
                                      : Icons.schedule,
                                  size: 10,
                                  color: message.isRead
                                      ? AppTheme.success
                                      : AppTheme.warning,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  message.isRead ? 'Read' : 'Pending',
                                  style: AppTheme.caption(
                                    size: 9,
                                    color: message.isRead
                                        ? AppTheme.success
                                        : AppTheme.warning,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Message preview
                      Text(
                        message.messagePreview,
                        style: AppTheme.body(
                          size: 13,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _getHintText(MessageCategory category) {
    switch (category) {
      case MessageCategory.bug:
        return 'Describe the bug you encountered...';
      case MessageCategory.question:
        return 'What would you like to know?';
      case MessageCategory.feature:
        return 'Describe the feature you\'d like to see...';
      case MessageCategory.other:
        return 'Enter your message...';
    }
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
