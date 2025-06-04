import 'package:flutter/material.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';

class EditProfileDialog extends StatefulWidget {
  final String username;
  final String bio;
  final String selectedProfileOption;
  final String selectedBackgroundOption;
  final List<String> imageProfileOptions;
  final List<String> imageBackgroundOptions;
  final Function(String, String, String, String) onSave;

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StyledTitle(
                "Edit Profile",
              ),
              const SizedBox(height: 20),

              // Username field
              TextField(
                controller: _usernameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Username",
                  labelStyle: const TextStyle(color: Colors.white),
                  hintText: "Enter new username",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) => newUsername = value,
              ),
              const SizedBox(height: 16),

              // Bio field
              TextField(
                controller: _bioController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Bio",
                  labelStyle: const TextStyle(color: Colors.white),
                  hintText: "Tell us about yourself",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) => newBio = value,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Profile Image Selection
              const Text(
                "Select Profile Image",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: Scrollbar(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.imageProfileOptions.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final option = widget.imageProfileOptions[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            newProfileImage = option;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: AssetImage('lib/assets/images/$option'),
                              fit: BoxFit.cover,
                            ),
                            border: newProfileImage == option
                                ? Border.all(color: Colors.deepOrange, width: 3)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Background Image Selection
              const Text(
                "Select Background Image",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: Scrollbar(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.imageBackgroundOptions.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final option = widget.imageBackgroundOptions[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            newBackgroundImage = option;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: AssetImage('lib/assets/images/$option'),
                              fit: BoxFit.cover,
                            ),
                            border: newBackgroundImage == option
                                ? Border.all(color: Colors.deepOrange, width: 3)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      widget.onSave(
                        newUsername,
                        newBio,
                        newProfileImage,
                        newBackgroundImage,
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
