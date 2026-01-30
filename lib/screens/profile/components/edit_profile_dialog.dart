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

  bool _isLoading = false;

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

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < minUsernameLength) {
      return 'Min $minUsernameLength characters';
    }
    if (value.trim().length > maxUsernameLength) {
      return 'Max $maxUsernameLength characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Letters, numbers, underscores only';
    }
    return null;
  }

  String? _validateBio(String? value) {
    if (value != null && value.length > maxBioLength) {
      return 'Max $maxBioLength characters';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

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
                Icon(Icons.check_circle, color: AppTheme.textWhite, size: 16),
                const SizedBox(width: 8),
                const Text('Profile updated!', style: TextStyle(fontSize: 13)),
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
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppTheme.textWhite, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed: $e', style: const TextStyle(fontSize: 13))),
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
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
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
                    style: AppTheme.heading(size: 18, color: AppTheme.textWhite),
                  ),
                ),
                const SizedBox(height: 14),

                // Username field
                _buildSectionHeader('Account'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  autofocus: true,
                  enabled: !_isLoading,
                  style: AppTheme.body(size: 13, color: AppTheme.textWhite),
                  maxLength: maxUsernameLength,
                  decoration: _inputDecoration(
                    label: 'Username',
                    hint: 'Enter username',
                    icon: Icons.person,
                  ),
                  validator: _validateUsername,
                  onChanged: (value) => newUsername = value,
                ),
                const SizedBox(height: 8),

                // Bio field
                TextFormField(
                  controller: _bioController,
                  enabled: !_isLoading,
                  style: AppTheme.body(size: 13, color: AppTheme.textWhite),
                  maxLength: maxBioLength,
                  maxLines: 2,
                  decoration: _inputDecoration(
                    label: 'Bio',
                    hint: 'Tell us about yourself',
                    icon: Icons.description,
                    alignTop: true,
                  ),
                  validator: _validateBio,
                  onChanged: (value) => newBio = value,
                ),
                const SizedBox(height: 14),

                // Profile Image
                _buildSectionHeader('Profile Image'),
                const SizedBox(height: 8),
                _buildImageGrid(
                  options: widget.imageProfileOptions,
                  selectedOption: newProfileImage,
                  onSelect: _isLoading ? null : (option) => setState(() => newProfileImage = option),
                  crossAxisCount: 5,
                  height: 120,
                ),
                const SizedBox(height: 14),

                // Background Image
                _buildSectionHeader('Background'),
                const SizedBox(height: 8),
                _buildImageGrid(
                  options: widget.imageBackgroundOptions,
                  selectedOption: newBackgroundImage,
                  onSelect: _isLoading ? null : (option) => setState(() => newBackgroundImage = option),
                  crossAxisCount: 3,
                  height: 100,
                ),
                const SizedBox(height: 14),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textLight,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text('Cancel', style: AppTheme.caption(size: 13, color: AppTheme.textLight)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: AppTheme.textWhite,
                        disabledBackgroundColor: AppTheme.secondary.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.borderRadiusSmall,
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textWhite),
                              ),
                            )
                          : Text('Save', style: AppTheme.caption(size: 13, color: AppTheme.textWhite, weight: FontWeight.w600)),
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    bool alignTop = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTheme.caption(size: 12, color: AppTheme.textLight),
      hintText: hint,
      hintStyle: AppTheme.caption(size: 12, color: AppTheme.textLight),
      counterStyle: AppTheme.caption(size: 10, color: AppTheme.textLight),
      filled: true,
      fillColor: AppTheme.backgroundDark,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: AppTheme.borderRadiusSmall,
        borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppTheme.borderRadiusSmall,
        borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTheme.borderRadiusSmall,
        borderSide: BorderSide(color: AppTheme.secondary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppTheme.borderRadiusSmall,
        borderSide: BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppTheme.borderRadiusSmall,
        borderSide: BorderSide(color: AppTheme.error, width: 1.5),
      ),
      prefixIcon: alignTop
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Icon(icon, color: AppTheme.textLight, size: 18),
            )
          : Icon(icon, color: AppTheme.textLight, size: 18),
      errorStyle: TextStyle(color: AppTheme.error, fontSize: 10),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTheme.caption(
            size: 12,
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
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.3)),
        color: AppTheme.backgroundDark,
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(6),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 6,
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
                    ? Border.all(color: AppTheme.secondary, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
              ),
              child: isSelected
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, size: 10, color: AppTheme.textWhite),
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
