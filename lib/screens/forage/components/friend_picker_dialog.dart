import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/friend.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A dialog for selecting specific friends who can view a marker.
///
/// Returns a list of selected friend email addresses.
class FriendPickerDialog extends ConsumerStatefulWidget {
  /// Initially selected friend emails
  final List<String> initialSelection;

  const FriendPickerDialog({
    Key? key,
    this.initialSelection = const [],
  }) : super(key: key);

  @override
  ConsumerState<FriendPickerDialog> createState() => _FriendPickerDialogState();

  /// Shows the dialog and returns the selected friend emails.
  static Future<List<String>?> show(
    BuildContext context, {
    List<String> initialSelection = const [],
  }) async {
    return showDialog<List<String>>(
      context: context,
      builder: (context) => FriendPickerDialog(
        initialSelection: initialSelection,
      ),
    );
  }
}

class _FriendPickerDialogState extends ConsumerState<FriendPickerDialog> {
  late Set<String> _selectedEmails;

  @override
  void initState() {
    super.initState();
    _selectedEmails = Set.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == null) {
      return AlertDialog(
        title: const Text('Error'),
        content: const Text('You must be logged in to select friends.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    final friendRepo = ref.read(friendRepositoryProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.people, color: AppTheme.accent),
          const SizedBox(width: 8),
          const Text('Select Friends'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: StreamBuilder<List<FriendModel>>(
          stream: friendRepo.streamFriends(currentUser!.email!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No friends yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add friends to share locations with them',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final friends = snapshot.data!;

            return Column(
              children: [
                // Select all / deselect all buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedEmails = friends.map((f) => f.friendEmail).toSet();
                        });
                      },
                      child: const Text('Select All'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedEmails.clear();
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final isSelected = _selectedEmails.contains(friend.friendEmail);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedEmails.add(friend.friendEmail);
                            } else {
                              _selectedEmails.remove(friend.friendEmail);
                            }
                          });
                        },
                        title: Text(friend.displayName),
                        subtitle: Text(
                          friend.friendEmail,
                          style: const TextStyle(fontSize: 12),
                        ),
                        secondary: CircleAvatar(
                          backgroundColor: AppTheme.accent.withOpacity(0.2),
                          child: Text(
                            friend.displayName.isNotEmpty
                                ? friend.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(color: AppTheme.accent),
                          ),
                        ),
                        activeColor: AppTheme.accent,
                        dense: true,
                      );
                    },
                  ),
                ),
                const Divider(),
                Text(
                  '${_selectedEmails.length} friend${_selectedEmails.length == 1 ? '' : 's'} selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context, _selectedEmails.toList());
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
