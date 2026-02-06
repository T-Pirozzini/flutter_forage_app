import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Dialog for sending a "Let's Forage Together" request to another user.
///
/// Features:
/// - For strangers: Short intro message (150 char limit, LinkedIn-style)
/// - For friends: Planning details (date, location, what to forage)
/// - Safety tips reminder
/// - Send request to ForageRequests collection
class SendForageRequestDialog extends ConsumerStatefulWidget {
  final String recipientUsername;
  final String recipientEmail;
  final String senderUsername;
  final String senderEmail;

  /// If true, shows planning UI instead of intro UI (for existing friends)
  final bool isFriend;

  const SendForageRequestDialog({
    super.key,
    required this.recipientUsername,
    required this.recipientEmail,
    required this.senderUsername,
    required this.senderEmail,
    this.isFriend = false,
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

  // Planning fields for friends
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  int get _remainingChars => _maxMessageLength - _messageController.text.length;

  String get _formattedDateTime {
    if (_selectedDate == null) return '';
    final dateStr = DateFormat('EEE, MMM d').format(_selectedDate!);
    if (_selectedTime != null) {
      final hour = _selectedTime!.hourOfPeriod == 0 ? 12 : _selectedTime!.hourOfPeriod;
      final period = _selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
      return '$dateStr at $hour:${_selectedTime!.minute.toString().padLeft(2, '0')} $period';
    }
    return dateStr;
  }

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
              widget.isFriend ? 'Plan a Forage' : "Let's Forage Together",
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
                          widget.isFriend
                              ? 'Plan a foraging trip'
                              : 'Send a forage request',
                          style: AppTheme.caption(size: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // For friends: Date/time picker
            if (widget.isFriend) ...[
              Text(
                'When do you want to go?',
                style: AppTheme.body(size: 14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _selectedDate != null
                            ? DateFormat('EEE, MMM d').format(_selectedDate!)
                            : 'Pick a date',
                        style: AppTheme.caption(size: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(context),
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Pick a time',
                        style: AppTheme.caption(size: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Message input - different labels for friend vs stranger
            Text(
              widget.isFriend ? 'Details & Location' : 'Introduce yourself',
              style: AppTheme.body(size: 14, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLength: _maxMessageLength,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: widget.isFriend
                    ? 'Let\'s check out the trails near Oak Grove. I\'ve heard there are chanterelles this time of year!'
                    : 'Hi! I noticed you\'re interested in foraging. I\'d love to connect and explore together sometime...',
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

            // Safety reminder - different for friends
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
                    widget.isFriend
                        ? 'After confirming, you can notify your emergency contacts about your foraging plans.'
                        : 'If accepted, you\'ll exchange contact info to coordinate off-platform. Always meet in public first and tell someone where you\'re going.',
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
              : Text(widget.isFriend ? 'Send Invite' : 'Send Request'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _sendRequest() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final forageRequestRepo = ref.read(forageRequestRepositoryProvider);

      // Build message - include date/time for friends
      String message = _messageController.text.trim();
      if (widget.isFriend && _formattedDateTime.isNotEmpty) {
        message = '📅 $_formattedDateTime\n\n$message';
      }

      await forageRequestRepo.sendRequest(
        fromEmail: widget.senderEmail,
        fromUsername: widget.senderUsername,
        toEmail: widget.recipientEmail,
        toUsername: widget.recipientUsername,
        message: message,
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
