import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/services/interstitial_ad_manager.dart';
import 'package:flutter_forager_app/data/models/ingredient.dart';
import 'package:flutter_forager_app/data/models/recipe.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
import 'package:flutter_forager_app/screens/recipes/components/forage_type_selector.dart';
import 'package:flutter_forager_app/screens/recipes/components/marker_picker_bottom_sheet.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_forager_app/shared/gamification/gamification_helper.dart';

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

  // Enhanced foraged ingredient fields
  String? _selectedForageType;
  final TextEditingController _prepNotesController = TextEditingController();
  final TextEditingController _substitutionController = TextEditingController();
  bool _showForagedDetails = false;
  MarkerModel? _linkedMarker;

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
            forageType: _isForaged ? _selectedForageType : null,
            prepNotes: _isForaged && _prepNotesController.text.trim().isNotEmpty
                ? _prepNotesController.text.trim()
                : null,
            substitution: _isForaged && _substitutionController.text.trim().isNotEmpty
                ? _substitutionController.text.trim()
                : null,
            linkedMarkerId: _linkedMarker?.id,
            linkedMarkerName: _linkedMarker?.name,
          ),
        );
        // Reset all ingredient input fields
        _ingredientController.clear();
        _quantityController.clear();
        _prepNotesController.clear();
        _substitutionController.clear();
        _isForaged = false;
        _selectedForageType = null;
        _showForagedDetails = false;
        _linkedMarker = null;
      });
    }
  }

  void _addStep() {
    final step = _stepController.text.trim();
    if (step.isNotEmpty) {
      setState(() {
        _steps.add(step);
        _stepController.clear();
      });
    }
  }

  void _showMarkerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MarkerPickerBottomSheet(
        filterByType: _selectedForageType,
        onMarkerSelected: (marker) {
          setState(() {
            _linkedMarker = marker;
            // Auto-fill ingredient name if empty
            if (_ingredientController.text.trim().isEmpty) {
              _ingredientController.text = marker.name;
            }
            // Auto-select forage type if not already selected
            if (_selectedForageType == null) {
              _selectedForageType = marker.type.toLowerCase();
            }
          });
        },
      ),
    );
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

        // Award points for creating a recipe
        if (mounted) {
          await GamificationHelper.awardRecipeCreated(
            context: context,
            ref: ref,
            userId: _userEmail,
          );
        }
      }

      _clearForm();
      _showSuccess();
      if (!_isEditing) {
        InterstitialAdManager.instance.tryShowAd();
      }
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

  Widget _buildPhotoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.textLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.textMedium),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.caption(
                size: 12,
                color: AppTheme.textMedium,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientChip(Ingredient ingredient) {
    final color = ingredient.isForaged
        ? (ingredient.forageType != null
            ? ForageTypeUtils.getTypeColor(ingredient.forageType!)
            : AppTheme.success)
        : AppTheme.textMedium;

    return Chip(
      avatar: ingredient.isForaged && ingredient.forageType != null
          ? ClipOval(
              child: Image.asset(
                'lib/assets/images/${ingredient.forageType}_marker.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.eco, size: 16, color: color);
                },
              ),
            )
          : Icon(
              ingredient.isForaged ? Icons.eco : Icons.shopping_cart_outlined,
              size: 16,
              color: color,
            ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${ingredient.quantity} ${ingredient.name}'),
          if (ingredient.hasLinkedLocation)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.location_on, size: 12, color: color),
            ),
        ],
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () => setState(() => _ingredients.remove(ingredient)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      labelStyle: TextStyle(
        color: color,
        fontSize: 13,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Recipe' : 'Share Recipe',
          style: AppTheme.heading(size: 18, color: AppTheme.textWhite),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Name
            Text(
              'Recipe Name*',
              style: AppTheme.body(
                size: 14,
                color: AppTheme.textDark,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
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
            Text(
              'Description (Optional)',
              style: AppTheme.body(
                size: 14,
                color: AppTheme.textDark,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
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
            Row(
              children: [
                Text(
                  'Photos',
                  style: AppTheme.body(
                    size: 14,
                    color: AppTheme.textDark,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_images.length}/3',
                  style: AppTheme.caption(
                    size: 12,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textLight.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  // Image grid
                  if (_images.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _images[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() => _images.removeAt(index)),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              // Primary badge for first image
                              if (index == 0)
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Cover',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  // Add photo buttons
                  if (_images.length < 3)
                    Padding(
                      padding: EdgeInsets.only(
                        left: 8,
                        right: 8,
                        top: _images.isEmpty ? 8 : 0,
                        bottom: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPhotoButton(
                              icon: Icons.photo_library_outlined,
                              label: 'Gallery',
                              onTap: () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPhotoButton(
                              icon: Icons.camera_alt_outlined,
                              label: 'Camera',
                              onTap: () => _pickImage(ImageSource.camera),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ingredients
            Text(
              'Ingredients*',
              style: AppTheme.body(
                size: 14,
                color: AppTheme.textDark,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            // Quantity and ingredient name row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      hintText: 'Qty',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _ingredientController,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      hintText: 'Ingredient name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Foraged checkbox
            GestureDetector(
              onTap: () {
                setState(() {
                  _isForaged = !_isForaged;
                  _showForagedDetails = _isForaged;
                  if (!_isForaged) {
                    _selectedForageType = null;
                    _prepNotesController.clear();
                    _substitutionController.clear();
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _isForaged
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isForaged
                        ? AppTheme.success
                        : AppTheme.textLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isForaged ? Icons.check_box : Icons.check_box_outline_blank,
                      color: _isForaged ? AppTheme.success : AppTheme.textMedium,
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.eco,
                      color: _isForaged ? AppTheme.success : AppTheme.textLight,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'This is a foraged ingredient',
                      style: TextStyle(
                        color: _isForaged ? AppTheme.success : AppTheme.textMedium,
                        fontWeight: _isForaged ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Foraged details section (collapsible)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Forage type selector
                    ForageTypeSelector(
                      selectedType: _selectedForageType,
                      onTypeSelected: (type) {
                        setState(() => _selectedForageType = type);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Link to forage location button
                    if (_linkedMarker == null)
                      OutlinedButton.icon(
                        onPressed: _showMarkerPicker,
                        icon: const Icon(Icons.add_location_alt, size: 18),
                        label: const Text('Link to My Forage Location'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Linked to:',
                                    style: AppTheme.caption(
                                      size: 10,
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                  Text(
                                    _linkedMarker!.name,
                                    style: AppTheme.body(
                                      size: 13,
                                      color: AppTheme.primary,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() => _linkedMarker = null);
                              },
                              color: AppTheme.textMedium,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Only friends can see the linked location',
                      style: AppTheme.caption(
                        size: 10,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Prep notes
                    Text(
                      'Prep notes (optional)',
                      style: AppTheme.caption(
                        size: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _prepNotesController,
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: 'e.g., Clean thoroughly, cook at least 10 min',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    // Store substitute
                    Text(
                      'Store substitute (optional)',
                      style: AppTheme.caption(
                        size: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _substitutionController,
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: 'e.g., Cremini or shiitake mushrooms',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              crossFadeState: _showForagedDetails
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),

            const SizedBox(height: 12),

            // Add ingredient button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Ingredient'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ingredient chips - grouped by foraged/store-bought
            if (_ingredients.any((i) => i.isForaged)) ...[
              Text(
                'Foraged (${_ingredients.where((i) => i.isForaged).length})',
                style: AppTheme.caption(
                  size: 12,
                  color: AppTheme.success,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ingredients
                    .where((i) => i.isForaged)
                    .map((ingredient) => _buildIngredientChip(ingredient))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            if (_ingredients.any((i) => !i.isForaged)) ...[
              Text(
                'Store-bought (${_ingredients.where((i) => !i.isForaged).length})',
                style: AppTheme.caption(
                  size: 12,
                  color: AppTheme.textMedium,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ingredients
                    .where((i) => !i.isForaged)
                    .map((ingredient) => _buildIngredientChip(ingredient))
                    .toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Instructions
            Row(
              children: [
                Text(
                  'Instructions*',
                  style: AppTheme.body(
                    size: 14,
                    color: AppTheme.textDark,
                    weight: FontWeight.w600,
                  ),
                ),
                if (_steps.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${_steps.length} step${_steps.length == 1 ? '' : 's'}',
                    style: AppTheme.caption(
                      size: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stepController,
                    decoration: InputDecoration(
                      hintText: 'Add a step...',
                      hintStyle: TextStyle(fontSize: 14, color: AppTheme.textLight),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onSubmitted: (_) => _addStep(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addStep,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            if (_steps.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Drag to reorder',
                style: AppTheme.caption(
                  size: 11,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 6),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _steps.removeAt(oldIndex);
                    _steps.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  return Container(
                    key: ValueKey('step_$index'),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.textLight.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Drag handle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: Icon(
                            Icons.drag_handle,
                            size: 18,
                            color: AppTheme.textLight,
                          ),
                        ),
                        // Step number
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Step text
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              _steps[index],
                              style: AppTheme.body(
                                size: 13,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ),
                        // Delete button
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: AppTheme.textLight,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _steps.removeAt(index)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),

            // Submit Button
            Consumer(
              builder: (context, ref, _) => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submitRecipe(ref),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: AppTheme.primary,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Recipe' : 'Submit Recipe',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
