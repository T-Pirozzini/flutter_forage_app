import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

class EditProfileDialog extends StatefulWidget {
  final String username;
  final String bio;
  final String selectedProfileOption;
  final String selectedBackgroundOption;
  final List<String> imageProfileOptions;
  final List<String> imageBackgroundOptions;
  final Future<void> Function(String, String, String, String) onSave;

  const EditProfileDialog({
    super.key,
    required this.username,
    required this.bio,
    required this.selectedProfileOption,
    required this.selectedBackgroundOption,
    required this.imageProfileOptions,
    required this.imageBackgroundOptions,
    required this.onSave,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late String newUsername;
  late String newBio;
  late String newProfileImage;
  late String newBackgroundImage;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Loading state
  bool _isLoading = false;

  // Validation constants
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int maxBioLength = 200;

  @override
  void initState() {
    super.initState();
    newUsername = widget.username;
    newBio = widget.bio;
    newProfileImage = widget.selectedProfileOption;
    newBackgroundImage = widget.selectedBackgroundOption;

    _usernameController.text = widget.username;
    _bioController.text = widget.bio;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Validation methods
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < minUsernameLength) {
      return 'Username must be at least $minUsernameLength characters';
    }
    if (value.trim().length > maxUsernameLength) {
      return 'Username must be at most $maxUsernameLength characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Only letters, numbers, and underscores allowed';
    }
    return null;
  }

  String? _validateBio(String? value) {
    if (value != null && value.length > maxBioLength) {
      return 'Bio must be at most $maxBioLength characters';
    }
    return null;
  }

  // Save with loading and error handling
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSave(
        newUsername.trim(),
        newBio,
        newProfileImage,
        newBackgroundImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.textWhite),
                const SizedBox(width: 8),
                const Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppTheme.textWhite),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to update profile: $e')),
              ],
            ),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusLarge,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Title
                Center(
                  child: Text(
                    'Edit Profile',
                    style: AppTheme.heading(
                      size: 22,
                      color: AppTheme.textWhite,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section: Account Details
                _buildSectionHeader('Account Details'),
                const SizedBox(height: 12),

                // Username field with validation and counter
                TextFormField(
                  controller: _usernameController,
                  autofocus: true,
                  enabled: !_isLoading,
                  style: AppTheme.body(color: AppTheme.textWhite),
                  maxLength: maxUsernameLength,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: AppTheme.caption(color: AppTheme.textLight),
                    hintText: 'Enter your username',
                    hintStyle: AppTheme.caption(color: AppTheme.textLight),
                    counterStyle: AppTheme.caption(
                      size: 12,
                      color: AppTheme.textLight,
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                      borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                      borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                      borderSide: BorderSide(color: AppTheme.secondary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                      borderSide: BorderSide(color: AppTheme.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                      borderSide: BorderSide(color: AppTheme.error, width: 2),
                    ),
                    prefixIcon: Icon(Icons.person, color: AppTheme.textLight),
                    errorStyle: TextStyle(color: AppTheme.error),
                  ),
                  validator: _validateUsername,
                  onChanged: (value) => newUsername = value,
                ),
                const SizedBox(height: 16),

                // Bio field with validation and counter
                TextFormField(
                  controller: _bioController,
                  enabled: !_isLoading,
                  style: AppTheme.body(color: AppTheme.textWhite),
                  maxLength: maxBioLength,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    labelStyle: AppTheme.caption(color: AppTheme.textLight),
                    hintText: 'Tell us about yourself',
                    hintStyle: AppTheme.caption(color: AppTheme.textLight),
                    counterStyle: AppTheme.caption(
                      size: 12,
                      color: AppTheme.textLight,
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                      borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                      borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                      borderSide: BorderSide(color: AppTheme.secondary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                      borderSide: BorderSide(color: AppTheme.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                      borderSide: BorderSide(color: AppTheme.error, width: 2),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.description, color: AppTheme.textLight),
                    ),
                    errorStyle: TextStyle(color: AppTheme.error),
                  ),
                  validator: _validateBio,
                  onChanged: (value) => newBio = value,
                ),
                const SizedBox(height: 24),

                // Section: Profile Image
                _buildSectionHeader('Profile Image'),
                const SizedBox(height: 12),
                _buildImageGrid(
                  options: widget.imageProfileOptions,
                  selectedOption: newProfileImage,
                  onSelect: _isLoading ? null : (option) => setState(() => newProfileImage = option),
                  crossAxisCount: 4,
                ),
                const SizedBox(height: 24),

                // Section: Background Image
                _buildSectionHeader('Background Image'),
                const SizedBox(height: 12),
                _buildImageGrid(
                  options: widget.imageBackgroundOptions,
                  selectedOption: newBackgroundImage,
                  onSelect: _isLoading ? null : (option) => setState(() => newBackgroundImage = option),
                  crossAxisCount: 3,
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textLight,
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTheme.button(color: AppTheme.textLight),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: AppTheme.textWhite,
                        disabledBackgroundColor: AppTheme.secondary.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.borderRadiusMedium,
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.textWhite,
                                ),
                              ),
                            )
                          : Text(
                              'Save',
                              style: AppTheme.button(color: AppTheme.textWhite),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.title(
            size: 16,
            color: AppTheme.textWhite,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid({
    required List<String> options,
    required String selectedOption,
    required Function(String)? onSelect,
    required int crossAxisCount,
  }) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.3)),
        color: AppTheme.backgroundDark,
      ),
      child: Scrollbar(
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = selectedOption == option;
            return GestureDetector(
              onTap: onSelect != null ? () => onSelect(option) : null,
              child: AnimatedContainer(
                duration: AppTheme.animationFast,
                decoration: BoxDecoration(
                  borderRadius: AppTheme.borderRadiusSmall,
                  image: DecorationImage(
                    image: AssetImage('lib/assets/images/$option'),
                    fit: BoxFit.cover,
                  ),
                  border: isSelected
                      ? Border.all(color: AppTheme.secondary, width: 3)
                      : Border.all(color: Colors.transparent, width: 3),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.secondary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: AppTheme.textWhite,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
