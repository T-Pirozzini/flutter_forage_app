import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dialog for creating custom marker types with emoji icons
class CustomMarkerTypeDialog extends ConsumerStatefulWidget {
  final Function(String name, String emoji) onTypeCreated;

  const CustomMarkerTypeDialog({
    super.key,
    required this.onTypeCreated,
  });

  @override
  ConsumerState<CustomMarkerTypeDialog> createState() =>
      _CustomMarkerTypeDialogState();
}

class _CustomMarkerTypeDialogState extends ConsumerState<CustomMarkerTypeDialog> {
  final _nameController = TextEditingController();
  String? _selectedEmoji;
  bool _isSaving = false;

  // Curated list of relevant emojis for foraging
  static const List<String> _emojis = [
    // Food & Plants
    '🍄', '🍇', '🍓', '🫐', '🍒', '🍎', '🍐', '🍑', '🍊', '🍋',
    '🌰', '🥜', '🫘', '🌿', '🌱', '🍀', '☘️', '🌾', '🌻', '🌼',
    // Nature
    '🌲', '🌳', '🌴', '🪴', '🎋', '🪻', '🌸', '🌺', '🌹', '💐',
    // Animals & Water
    '🐟', '🐠', '🦐', '🦀', '🦞', '🦑', '🐚', '🐝', '🦋', '🐛',
    // Symbols
    '⭐', '💎', '🔮', '🎯', '📍', '🏷️', '💡', '🔔', '❤️', '✨',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomType() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedEmoji == null) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      final repo = ref.read(customMarkerTypeRepositoryProvider);

      // Check limit
      if (await repo.hasReachedLimit(user.email!)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 20 custom types allowed'),
            ),
          );
        }
        return;
      }

      // Create the custom type
      await repo.createType(
        name: name,
        emoji: _selectedEmoji!,
        userId: user.email!,
      );

      if (mounted) {
        widget.onTypeCreated(name, _selectedEmoji!);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating type: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.add_circle, color: AppTheme.accent),
          const SizedBox(width: 8),
          Text(
            'Custom Marker Type',
            style: AppTheme.title(size: 16, weight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Type Name',
                hintText: 'e.g., Wild Garlic',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.backgroundLight,
              ),
              maxLength: 20,
            ),
            const SizedBox(height: 16),

            // Emoji selection
            Text(
              'Choose an Emoji',
              style: AppTheme.caption(color: AppTheme.textMedium),
            ),
            const SizedBox(height: 8),

            // Emoji grid
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.backgroundLight),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  final emoji = _emojis[index];
                  final isSelected = emoji == _selectedEmoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = emoji),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accent.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: AppTheme.accent, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Preview
            if (_selectedEmoji != null && _nameController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedEmoji!,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preview',
                            style: AppTheme.caption(color: AppTheme.textLight),
                          ),
                          Text(
                            _nameController.text,
                            style: AppTheme.title(size: 14),
                          ),
                        ],
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
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppTheme.textMedium),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedEmoji != null &&
                  _nameController.text.trim().isNotEmpty &&
                  !_isSaving
              ? _saveCustomType
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

/// Show the custom marker type dialog
Future<void> showCustomMarkerTypeDialog(
  BuildContext context, {
  required Function(String name, String emoji) onTypeCreated,
}) {
  return showDialog(
    context: context,
    builder: (context) => CustomMarkerTypeDialog(
      onTypeCreated: onTypeCreated,
    ),
  );
}
