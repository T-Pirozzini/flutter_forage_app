import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/friend.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Dialog for notifying emergency contacts before a forage meetup.
///
/// Allows the user to:
/// - Select date and time of the forage
/// - Enter a general location/area
/// - Add optional notes
/// - Select which emergency contacts to notify
class NotifyEmergencyContactDialog extends ConsumerStatefulWidget {
  final String partnerUsername;

  const NotifyEmergencyContactDialog({
    super.key,
    required this.partnerUsername,
  });

  @override
  ConsumerState<NotifyEmergencyContactDialog> createState() =>
      _NotifyEmergencyContactDialogState();
}

class _NotifyEmergencyContactDialogState
    extends ConsumerState<NotifyEmergencyContactDialog> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  List<FriendModel> _emergencyContacts = [];
  Set<String> _selectedContacts = {};
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyContacts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == null) return;

    final friendRepo = ref.read(friendRepositoryProvider);
    final contacts = await friendRepo.getEmergencyContacts(currentUser!.email!);

    setState(() {
      _emergencyContacts = contacts;
      // Select all emergency contacts by default
      _selectedContacts = contacts.map((c) => c.friendEmail).toSet();
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  DateTime get _plannedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      title: Row(
        children: [
          Icon(Icons.security, color: AppTheme.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Notify Emergency Contacts',
              style: AppTheme.title(size: 18),
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppTheme.info),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Let your emergency contacts know about your planned forage with ${widget.partnerUsername}.',
                            style: AppTheme.caption(size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Date and Time
                  Text(
                    'When',
                    style: AppTheme.body(size: 14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            DateFormat('EEE, MMM d').format(_selectedDate),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectTime,
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(_selectedTime.format(context)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Location
                  Text(
                    'General Area',
                    style: AppTheme.body(size: 14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Stanley Park, North Shore trails',
                      hintStyle: AppTheme.body(
                        size: 14,
                        color: AppTheme.textMedium.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 20),

                  // Notes
                  Text(
                    'Notes (optional)',
                    style: AppTheme.body(size: 14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Any additional details...',
                      hintStyle: AppTheme.body(
                        size: 14,
                        color: AppTheme.textMedium.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Emergency contacts selection
                  Text(
                    'Notify',
                    style: AppTheme.body(size: 14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  if (_emergencyContacts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: AppTheme.warning, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No emergency contacts set',
                                  style: AppTheme.caption(
                                    size: 13,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Go to Friends and mark trusted friends as emergency contacts.',
                                  style: AppTheme.caption(size: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._emergencyContacts.map((contact) {
                      final isSelected =
                          _selectedContacts.contains(contact.friendEmail);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedContacts.add(contact.friendEmail);
                            } else {
                              _selectedContacts.remove(contact.friendEmail);
                            }
                          });
                        },
                        title: Text(
                          contact.displayName,
                          style: AppTheme.body(size: 14),
                        ),
                        subtitle: Text(
                          contact.friendEmail,
                          style: AppTheme.caption(size: 11),
                        ),
                        secondary: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.warning,
                          child: const Icon(
                            Icons.shield,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    }),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: AppTheme.body(color: AppTheme.textMedium)),
        ),
        ElevatedButton(
          onPressed: _canSend ? _sendNotification : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.warning,
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
              : const Text('Notify Contacts'),
        ),
      ],
    );
  }

  bool get _canSend {
    return !_isSending &&
        _locationController.text.trim().isNotEmpty &&
        _selectedContacts.isNotEmpty;
  }

  Future<void> _sendNotification() async {
    if (!_canSend) return;

    setState(() => _isSending = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email == null) return;

      final userRepo = ref.read(userRepositoryProvider);
      final emergencyRepo = ref.read(emergencyNotificationRepositoryProvider);

      final userData = await userRepo.getById(currentUser!.email!);

      await emergencyRepo.createNotification(
        userId: currentUser.email!,
        userEmail: currentUser.email!,
        username: userData?.username ?? currentUser.email!,
        partnerUsername: widget.partnerUsername,
        plannedDateTime: _plannedDateTime,
        generalLocation: _locationController.text.trim(),
        emergencyContactEmails: _selectedContacts.toList(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
