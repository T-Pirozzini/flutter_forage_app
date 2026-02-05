import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Dialog for responding to a forage request (accept or decline).
///
/// Allows the user to optionally include a short response message.
class RespondToRequestDialog extends StatefulWidget {
  final String senderUsername;
  final bool isAccepting;

  const RespondToRequestDialog({
    super.key,
    required this.senderUsername,
    required this.isAccepting,
  });

  @override
  State<RespondToRequestDialog> createState() => _RespondToRequestDialogState();
}

class _RespondToRequestDialogState extends State<RespondToRequestDialog> {
  final TextEditingController _messageController = TextEditingController();
  static const int _maxMessageLength = 150;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAccepting = widget.isAccepting;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      title: Row(
        children: [
          Icon(
            isAccepting ? Icons.check_circle : Icons.cancel,
            color: isAccepting ? AppTheme.success : AppTheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAccepting ? 'Accept Request' : 'Decline Request',
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
            Text(
              isAccepting
                  ? 'Accept the forage request from ${widget.senderUsername}?'
                  : 'Decline the forage request from ${widget.senderUsername}?',
              style: AppTheme.body(size: 14),
            ),

            const SizedBox(height: 16),

            // Optional response message
            Text(
              'Add a message (optional)',
              style: AppTheme.caption(size: 12, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLength: _maxMessageLength,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isAccepting
                    ? 'Great! Looking forward to connecting...'
                    : 'Thanks for reaching out, but...',
                hintStyle: AppTheme.body(
                  size: 13,
                  color: AppTheme.textMedium.withValues(alpha: 0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            if (isAccepting) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'After accepting, you\'ll be prompted to share your contact info to connect off-platform.',
                        style: AppTheme.caption(size: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancel', style: AppTheme.body(color: AppTheme.textMedium)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'message': _messageController.text.trim().isEmpty
                  ? null
                  : _messageController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isAccepting ? AppTheme.success : AppTheme.error,
            foregroundColor: Colors.white,
          ),
          child: Text(isAccepting ? 'Accept' : 'Decline'),
        ),
      ],
    );
  }
}
