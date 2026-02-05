import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dialog for sending a "Let's Forage Together" request to another user.
///
/// Features:
/// - Short intro message (150 char limit, LinkedIn-style)
/// - Safety tips reminder
/// - Send request to ForageRequests collection
class SendForageRequestDialog extends ConsumerStatefulWidget {
  final String recipientUsername;
  final String recipientEmail;
  final String senderUsername;
  final String senderEmail;

  const SendForageRequestDialog({
    super.key,
    required this.recipientUsername,
    required this.recipientEmail,
    required this.senderUsername,
    required this.senderEmail,
  });

  @override
  ConsumerState<SendForageRequestDialog> createState() =>
      _SendForageRequestDialogState();
}

class _SendForageRequestDialogState
    extends ConsumerState<SendForageRequestDialog> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
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
          Icon(Icons.nature_people, color: AppTheme.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Let's Forage Together",
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
                          'Send a forage request',
                          style: AppTheme.caption(size: 12),
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
              'Introduce yourself',
              style: AppTheme.body(size: 14, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLength: _maxMessageLength,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Hi! I noticed you\'re interested in foraging. I\'d love to connect and explore together sometime...',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, size: 16, color: AppTheme.info),
                      const SizedBox(width: 6),
                      Text(
                        'Safety First',
                        style: AppTheme.caption(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppTheme.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'If accepted, you\'ll exchange contact info to coordinate off-platform. Always meet in public first and tell someone where you\'re going.',
                    style: AppTheme.caption(size: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: AppTheme.body(color: AppTheme.textMedium),
          ),
        ),
        ElevatedButton(
          onPressed: _isSending || _messageController.text.trim().isEmpty
              ? null
              : _sendRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: Colors.white,
          ),
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Send Request'),
        ),
      ],
    );
  }

  Future<void> _sendRequest() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final forageRequestRepo = ref.read(forageRequestRepositoryProvider);

      await forageRequestRepo.sendRequest(
        fromEmail: widget.senderEmail,
        fromUsername: widget.senderUsername,
        toEmail: widget.recipientEmail,
        toUsername: widget.recipientUsername,
        message: _messageController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
