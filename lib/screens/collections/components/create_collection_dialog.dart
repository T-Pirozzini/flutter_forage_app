import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/location_collection.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateCollectionDialog extends ConsumerStatefulWidget {
  const CreateCollectionDialog({Key? key}) : super(key: key);

  static Future<LocationCollectionModel?> show(BuildContext context) {
    return showDialog<LocationCollectionModel>(
      context: context,
      builder: (context) => const CreateCollectionDialog(),
    );
  }

  @override
  ConsumerState<CreateCollectionDialog> createState() =>
      _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends ConsumerState<CreateCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Collection'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Collection Name',
                  hintText: 'e.g., Best Mushroom Spots',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  if (value.length > 50) {
                    return 'Name must be 50 characters or less';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Describe this collection...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Make Public'),
                subtitle: Text(
                  _isPublic
                      ? 'Friends can discover and subscribe'
                      : 'Only you can see this collection',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createCollection,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
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

  Future<void> _createCollection() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final collectionRepo = ref.read(collectionRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      // Get user display name
      final userData = await userRepo.getById(user!.email!);
      final displayName = userData?.username ?? user.email!;

      final collectionId = await collectionRepo.createCollection(
        userId: user.email!,
        userDisplayName: displayName,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        isPublic: _isPublic,
      );

      // Create the model to return
      final collection = LocationCollectionModel(
        id: collectionId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        isPublic: _isPublic,
        createdAt: DateTime.now(),
        markerIds: [],
        ownerEmail: user.email!,
        ownerDisplayName: displayName,
      );

      if (mounted) {
        Navigator.pop(context, collection);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create collection: $e')),
        );
      }
    }
  }
}
