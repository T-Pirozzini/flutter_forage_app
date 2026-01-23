import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/ingredient.dart';
import 'package:flutter_forager_app/data/models/recipe.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class AddRecipePage extends ConsumerStatefulWidget {
  final Recipe? recipeToEdit;
  const AddRecipePage({Key? key, this.recipeToEdit}) : super(key: key);
  @override
  ConsumerState<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends ConsumerState<AddRecipePage> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  final List<String> _existingImageUrls = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _stepController = TextEditingController();
  final List<Ingredient> _ingredients = [];
  final List<String> _steps = [];
  final String _userEmail = FirebaseAuth.instance.currentUser!.email!;
  String? _username;
  bool _isForaged = false;
  bool _isSubmitting = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.recipeToEdit != null;

    if (_isEditing) {
      // Populate form with existing recipe data
      _nameController.text = widget.recipeToEdit!.name;
      _descriptionController.text = widget.recipeToEdit!.description ?? '';
      _ingredients.addAll(widget.recipeToEdit!.ingredients);
      _steps.addAll(widget.recipeToEdit!.steps);
      _existingImageUrls.addAll(widget.recipeToEdit!.imageUrls);
    }

    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final user = await userRepo.getById(_userEmail);
      if (user != null) {
        setState(() {
          _username = user.username;
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 3 photos allowed'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<String> _uploadImageToFirebaseStorage(File image) async {
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: 70,
      );

      final fileName = '${DateTime.now().microsecondsSinceEpoch}.png';
      final destination = 'recipes/$fileName';

      final ref = firebase_storage.FirebaseStorage.instance.ref(destination);
      final metadata = firebase_storage.SettableMetadata(
        contentType: 'image/png',
      );

      await ref.putData(compressedImage!, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  void _addIngredient() {
    final ingredientName = _ingredientController.text.trim();
    final quantity = _quantityController.text.trim();
    if (ingredientName.isNotEmpty && quantity.isNotEmpty) {
      setState(() {
        _ingredients.add(
          Ingredient(
            name: ingredientName,
            quantity: quantity,
            isForaged: _isForaged,
          ),
        );
        _ingredientController.clear();
        _quantityController.clear();
        _isForaged = false;
      });
    }
  }

  Future<void> _submitRecipe(WidgetRef ref) async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter a recipe name');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload new images (if any)
      final List<String> newImageUrls = _images.isNotEmpty
          ? (await Future.wait(
              _images.map((image) => _uploadImageToFirebaseStorage(image)),
            )).cast<String>()
          : <String>[];

      // Combine new and existing images
      final List<String> allImageUrls = [
        ..._existingImageUrls,
        ...newImageUrls,
      ];

      final recipeRepo = ref.read(recipeRepositoryProvider);

      final recipe = Recipe(
        id: _isEditing
            ? widget.recipeToEdit!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        ingredients: _ingredients,
        steps: _steps,
        imageUrls: allImageUrls,
        timestamp: _isEditing ? widget.recipeToEdit!.timestamp : DateTime.now(),
        userEmail: _userEmail,
        userName: _username!,
        likes: _isEditing ? widget.recipeToEdit!.likes : [],
      );

      if (_isEditing) {
        // Update existing recipe
        await recipeRepo.update(recipe.id, recipe.toMap());
      } else {
        // Create new recipe
        await recipeRepo.create(recipe, id: recipe.id);
      }

      _clearForm();
      _showSuccess();
      Navigator.pop(context);
    } catch (e) {
      _showError('Failed to ${_isEditing ? 'update' : 'submit'} recipe: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _ingredientController.clear();
      _quantityController.clear();
      _stepController.clear();
      _images.clear();
      _ingredients.clear();
      _steps.clear();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recipe submitted successfully!'),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StyledTitleLarge(
          _isEditing ? 'Edit Recipe' : 'Share A Recipe',
          color: AppTheme.textDark,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Name
            StyledHeadingMedium('Recipe Name*', color: AppTheme.textDark),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Wild Mushroom Risotto',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            StyledHeadingMedium(
              'Description (Optional)',
              color: AppTheme.textDark,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                hintText:
                    'Tell us about this recipe or your foraging experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Photos
            StyledHeadingMedium('Photos (Max 3)', color: AppTheme.textDark),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._images.map(
                    (image) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              image,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _images.remove(image)),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_images.length < 3)
                    GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 30,
                              color: Colors.grey,
                            ),
                            Text(
                              'Add Photo',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Ingredients
            StyledHeadingMedium('Ingredients*', color: AppTheme.textDark),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      hintText: 'Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _ingredientController,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      hintText: 'Ingredient',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Text('Foraged?', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _isForaged,
                      onChanged: (value) => setState(() => _isForaged = value),
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.green),
                  onPressed: _addIngredient,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ingredients
                  .map(
                    (ingredient) => Chip(
                      label: Text('${ingredient.quantity} ${ingredient.name}'),
                      deleteIcon: Icon(Icons.close, size: 18),
                      onDeleted: () =>
                          setState(() => _ingredients.remove(ingredient)),
                      backgroundColor: ingredient.isForaged
                          ? Colors.green[50]
                          : Colors.grey[100],
                      labelStyle: TextStyle(
                        color: ingredient.isForaged
                            ? Colors.green[800]
                            : Colors.grey[800],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),

            // Instructions
            StyledHeadingMedium('Instructions*', color: AppTheme.textDark),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stepController,
                    decoration: InputDecoration(
                      hintText: 'Add step by step instructions',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () {
                    final step = _stepController.text.trim();
                    if (step.isNotEmpty) {
                      setState(() {
                        _steps.add(step);
                        _stepController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._steps.asMap().entries.map(
              (entry) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue,
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(entry.value)),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red[300],
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _steps.removeAt(entry.key)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button
            Consumer(
              builder: (context, ref, _) => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submitRecipe(ref),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.deepOrange,
                  ),
                  child: _isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Submit Recipe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
