import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Dialog for sending a friend request with an optional intro message.
///
/// Similar to LinkedIn connection requests - allows users to introduce
/// themselves when reaching out to connect.
class SendFriendRequestDialog extends StatefulWidget {
  final String recipientUsername;
  final String recipientEmail;

  const SendFriendRequestDialog({
    super.key,
    required this.recipientUsername,
    required this.recipientEmail,
  });

  @override
  State<SendFriendRequestDialog> createState() =>
      _SendFriendRequestDialogState();
}

class _SendFriendRequestDialogState extends State<SendFriendRequestDialog> {
  final TextEditingController _messageController = TextEditingController();
  static const int _maxMessageLength = 150;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  int get _remainingChars => _maxMessageLength - _messageController.text.length;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      title: Row(
        children: [
          Icon(Icons.person_add, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Send Friend Request',
              style: AppTheme.title(size: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipient info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      widget.recipientUsername.isNotEmpty
                          ? widget.recipientUsername[0].toUpperCase()
                          : '?',
                      style: AppTheme.title(color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recipientUsername,
                          style: AppTheme.title(size: 14),
                        ),
                        Text(
                          widget.recipientEmail,
                          style: AppTheme.caption(size: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Message input
            Text(
              'Add a message (optional)',
              style: AppTheme.body(size: 14, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLength: _maxMessageLength,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Hi! I found you through the Forager app. I\'d love to connect and share forage spots...',
                hintStyle: AppTheme.body(
                  size: 13,
                  color: AppTheme.textMedium.withValues(alpha: 0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),

            // Character counter
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$_remainingChars characters remaining',
                style: AppTheme.caption(
                  size: 11,
                  color: _remainingChars < 20
                      ? AppTheme.warning
                      : AppTheme.textMedium,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Safety reminder
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security, size: 16, color: AppTheme.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Once connected, you can share forage locations. Close friends see precise coordinates.',
                      style: AppTheme.caption(size: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            'Cancel',
            style: AppTheme.body(color: AppTheme.textMedium),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'send': true,
              'message': _messageController.text.trim().isEmpty
                  ? null
                  : _messageController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Send Request'),
        ),
      ],
    );
  }
}
