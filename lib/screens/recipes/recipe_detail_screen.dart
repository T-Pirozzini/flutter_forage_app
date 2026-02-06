import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/models/ingredient.dart';
import 'package:flutter_forager_app/data/models/recipe.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/recipes/add_recipe_page.dart';
import 'package:flutter_forager_app/shared/gamification/gamification_helper.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Full-screen detail view for a recipe
///
/// Shows:
/// - Tappable image gallery
/// - Recipe header with name, author, date
/// - Ingredients with foraged/purchased icons
/// - Numbered instructions
/// - Like and save action buttons
/// - Comments section
class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;
  final VoidCallback? onRecipeUpdated;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.onRecipeUpdated,
  });

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final dateFormat = DateFormat('MMMM d, yyyy');
  final _commentController = TextEditingController();

  bool _isLiked = false;
  bool _isSaved = false;
  int _likeCount = 0;
  int _saveCount = 0;
  bool _isFriendOfOwner = false;

  // Cache for user data to avoid repeated lookups
  final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _likeCount = widget.recipe.likeCount;
    _saveCount = widget.recipe.saveCount;
    _checkInitialStates();
    _checkFriendStatus();
  }

  Future<void> _checkFriendStatus() async {
    if (currentUser?.email == null) return;

    // Check if current user is the recipe owner
    if (currentUser!.email == widget.recipe.userEmail) {
      setState(() => _isFriendOfOwner = true);
      return;
    }

    // Check if current user is friends with the recipe owner
    try {
      final friendRepo = ref.read(friendRepositoryProvider);
      final isFriend = await friendRepo.areFriends(
        currentUser!.email!,
        widget.recipe.userEmail,
      );
      if (mounted) {
        setState(() => _isFriendOfOwner = isFriend);
      }
    } catch (e) {
      debugPrint('Error checking friend status: $e');
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Fetch user data with caching to avoid repeated lookups
  Future<Map<String, dynamic>> _getUserData(String userEmail) async {
    // Return cached data if available
    if (_userCache.containsKey(userEmail)) {
      return _userCache[userEmail]!;
    }

    // Fetch from Firestore
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userEmail)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        _userCache[userEmail] = data;
        return data;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }

    // Return empty map if not found
    return {};
  }

  Future<void> _checkInitialStates() async {
    if (currentUser?.email == null) return;

    final recipeRepo = ref.read(recipeRepositoryProvider);
    final savedRecipeRepo = ref.read(savedRecipeRepositoryProvider);

    final isLiked = await recipeRepo.hasUserLiked(
      widget.recipe.id,
      currentUser!.email!,
    );

    final isSaved = await savedRecipeRepo.isSaved(
      currentUser!.email!,
      widget.recipe.id,
    );

    if (mounted) {
      setState(() {
        _isLiked = isLiked;
        _isSaved = isSaved;
      });
    }
  }

  bool get _isOwner =>
      currentUser?.email != null &&
      widget.recipe.userEmail == currentUser!.email;

  Future<void> _toggleLike() async {
    if (currentUser?.email == null) return;

    final recipeRepo = ref.read(recipeRepositoryProvider);
    final wasLiked = _isLiked;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      await recipeRepo.toggleLike(
        recipeId: widget.recipe.id,
        userEmail: currentUser!.email!,
        isCurrentlyLiked: wasLiked,
      );
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
    }
  }

  Future<void> _toggleSave() async {
    if (currentUser?.email == null) return;

    final savedRecipeRepo = ref.read(savedRecipeRepositoryProvider);
    final wasSaved = _isSaved;

    setState(() {
      _isSaved = !_isSaved;
      _saveCount += _isSaved ? 1 : -1;
    });

    try {
      await savedRecipeRepo.toggleSave(
        userId: currentUser!.email!,
        recipe: widget.recipe,
      );

      // Award points when saving (not unsaving)
      if (_isSaved && mounted) {
        await GamificationHelper.awardRecipeSaved(
          context: context,
          ref: ref,
          userId: currentUser!.email!,
        );
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isSaved = wasSaved;
          _saveCount += wasSaved ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update save: $e')),
        );
      }
    }
  }

  Future<void> _deleteRecipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: const Text(
          'Are you sure you want to delete this recipe? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete recipe document
      await FirebaseFirestore.instance
          .collection('Recipes')
          .doc(widget.recipe.id)
          .delete();

      // Delete associated comments subcollection
      final comments = await FirebaseFirestore.instance
          .collection('Recipes')
          .doc(widget.recipe.id)
          .collection('Comments')
          .get();

      for (final doc in comments.docs) {
        await doc.reference.delete();
      }

      // Delete likes subcollection
      final likes = await FirebaseFirestore.instance
          .collection('Recipes')
          .doc(widget.recipe.id)
          .collection('Likes')
          .get();

      for (final doc in likes.docs) {
        await doc.reference.delete();
      }

      // Delete images from storage
      for (final url in widget.recipe.imageUrls) {
        try {
          final ref =
              firebase_storage.FirebaseStorage.instance.refFromURL(url);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting image: $e');
        }
      }

      if (mounted) {
        widget.onRecipeUpdated?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete recipe: $e')),
        );
      }
    }
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecipePage(recipeToEdit: widget.recipe),
      ),
    ).then((_) {
      widget.onRecipeUpdated?.call();
    });
  }

  void _showFullScreenImage(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageGallery(
          imageUrls: widget.recipe.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _addComment(String text) async {
    if (text.isEmpty || currentUser == null) return;

    try {
      // Fetch user's display name and profile pic
      String displayName = currentUser!.email?.split('@')[0] ?? 'User';
      String? profilePic;

      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.email)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        displayName = userData?['username'] ?? displayName;
        profilePic = userData?['profilePic'];
      }

      await FirebaseFirestore.instance
          .collection('Recipes')
          .doc(widget.recipe.id)
          .collection('Comments')
          .add({
        'userId': currentUser!.uid,
        'userEmail': currentUser!.email,
        'username': displayName,
        'profilePic': profilePic,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update comment count
      await FirebaseFirestore.instance
          .collection('Recipes')
          .doc(widget.recipe.id)
          .update({
        'commentCount': FieldValue.increment(1),
      });

      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          widget.recipe.name,
          style: AppTheme.heading(size: 18, color: Colors.white),
        ),
        actions: [
          if (_isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _navigateToEdit,
              tooltip: 'Edit Recipe',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _deleteRecipe,
              tooltip: 'Delete Recipe',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery
            _buildImageGallery(),

            // Recipe Header
            _buildRecipeHeader(),

            // Action Buttons
            _buildActionButtons(),

            // Ingredients Section
            _buildIngredientsSection(),

            // Instructions Section
            _buildInstructionsSection(),

            // Comments Section
            _buildCommentsSection(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    if (widget.recipe.imageUrls.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: AppTheme.surfaceLight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: AppTheme.textLight),
            const SizedBox(height: 8),
            Text(
              'No images',
              style: AppTheme.body(color: AppTheme.textMedium),
            ),
          ],
        ),
      );
    }

    // Tappable grid gallery for images
    return Container(
      padding: const EdgeInsets.all(8),
      child: widget.recipe.imageUrls.length == 1
          ? _buildSingleImage()
          : _buildImageGrid(),
    );
  }

  Widget _buildSingleImage() {
    return GestureDetector(
      onTap: () => _showFullScreenImage(0),
      child: ClipRRect(
        borderRadius: AppTheme.borderRadiusMedium,
        child: CachedNetworkImage(
          imageUrl: widget.recipe.imageUrls.first,
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 250,
            color: AppTheme.surfaceLight,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 250,
            color: AppTheme.surfaceLight,
            child: Icon(Icons.image_not_supported, color: AppTheme.textLight),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.recipe.imageUrls.length >= 3 ? 3 : 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: widget.recipe.imageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showFullScreenImage(index),
          child: ClipRRect(
            borderRadius: AppTheme.borderRadiusSmall,
            child: CachedNetworkImage(
              imageUrl: widget.recipe.imageUrls[index],
              fit: BoxFit.cover,
              memCacheHeight: 300,
              placeholder: (context, url) => Container(
                color: AppTheme.surfaceLight,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppTheme.surfaceLight,
                child: Icon(Icons.image_not_supported, color: AppTheme.textLight),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipeHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.recipe.name,
            style: AppTheme.heading(size: 24, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                child: Text(
                  widget.recipe.userName.isNotEmpty
                      ? widget.recipe.userName[0].toUpperCase()
                      : '?',
                  style: AppTheme.body(color: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${widget.recipe.userName}',
                      style: AppTheme.body(
                        size: 14,
                        color: AppTheme.textDark,
                        weight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      dateFormat.format(widget.recipe.timestamp),
                      style: AppTheme.caption(color: AppTheme.textMedium),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.favorite,
              label: '$_likeCount likes',
              isActive: _isLiked,
              activeColor: AppTheme.accent,
              onTap: _toggleLike,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.bookmark,
              label: '$_saveCount saved',
              isActive: _isSaved,
              activeColor: AppTheme.secondary,
              onTap: _toggleSave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : AppTheme.surfaceLight,
          borderRadius: AppTheme.borderRadiusMedium,
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.3)
                : AppTheme.textLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : AppTheme.textMedium,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.body(
                size: 14,
                color: isActive ? activeColor : AppTheme.textMedium,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    final foragedIngredients =
        widget.recipe.ingredients.where((i) => i.isForaged).toList();
    final purchasedIngredients =
        widget.recipe.ingredients.where((i) => !i.isForaged).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.kitchen, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ingredients',
                style: AppTheme.heading(size: 18, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Foraged ingredients
          if (foragedIngredients.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.eco, size: 16, color: AppTheme.success),
                const SizedBox(width: 6),
                Text(
                  'Foraged (${foragedIngredients.length})',
                  style: AppTheme.caption(
                    size: 12,
                    color: AppTheme.success,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...foragedIngredients.map((ingredient) => _buildEnhancedIngredientTile(ingredient)),
            const SizedBox(height: 12),
          ],

          // Purchased ingredients
          if (purchasedIngredients.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.shopping_basket, size: 16, color: AppTheme.secondary),
                const SizedBox(width: 6),
                Text(
                  'Purchased (${purchasedIngredients.length})',
                  style: AppTheme.caption(
                    size: 12,
                    color: AppTheme.secondary,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...purchasedIngredients.map((ingredient) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${ingredient.quantity} ${ingredient.name}',
                        style: AppTheme.body(size: 14, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  /// Enhanced ingredient tile for foraged ingredients with type icon,
  /// prep notes, substitutions, and friend-only location links.
  Widget _buildEnhancedIngredientTile(Ingredient ingredient) {
    final hasDetails = ingredient.forageType != null ||
        ingredient.prepNotes != null ||
        ingredient.substitution != null ||
        ingredient.hasLinkedLocation;

    // Get type color if available
    final typeColor = ingredient.forageType != null
        ? ForageTypeUtils.getTypeColor(ingredient.forageType!)
        : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main ingredient row with type icon
          Row(
            children: [
              // Type icon or default eco icon
              if (ingredient.forageType != null)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Image.asset(
                      'lib/assets/images/${ingredient.forageType!.toLowerCase()}_marker.png',
                      width: 18,
                      height: 18,
                      errorBuilder: (context, error, stackTrace) {
                        return ForageTypeUtils.getTypeIcon(ingredient.forageType!, size: 16);
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.eco, size: 16, color: AppTheme.success),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${ingredient.quantity} ${ingredient.name}',
                  style: AppTheme.body(
                    size: 14,
                    color: AppTheme.textDark,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
              // Type badge
              if (ingredient.forageType != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ForageTypeUtils.normalizeType(ingredient.forageType!),
                    style: AppTheme.caption(size: 10, color: typeColor),
                  ),
                ),
            ],
          ),

          // Details section (prep notes, substitution, location)
          if (hasDetails) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(left: 38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linked location (friends only)
                  if (ingredient.hasLinkedLocation)
                    _buildLinkedLocationRow(ingredient),

                  // Prep notes
                  if (ingredient.prepNotes != null && ingredient.prepNotes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.restaurant, size: 12, color: AppTheme.textMedium),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Prep: ${ingredient.prepNotes}',
                              style: AppTheme.caption(size: 12, color: AppTheme.textMedium),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Substitution
                  if (ingredient.substitution != null && ingredient.substitution!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.swap_horiz, size: 12, color: AppTheme.secondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Sub: ${ingredient.substitution}',
                              style: AppTheme.caption(size: 12, color: AppTheme.secondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the linked location row with friend-only visibility.
  /// Friends and the recipe owner can see the location name and tap to view.
  /// Non-friends see a message to add friend to reveal.
  Widget _buildLinkedLocationRow(Ingredient ingredient) {
    if (_isFriendOfOwner) {
      // Friends and owner can see the location
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: GestureDetector(
          onTap: () => _navigateToMarker(ingredient.linkedMarkerId!),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 12, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ingredient.linkedMarkerName ?? 'View location',
                  style: AppTheme.caption(
                    size: 12,
                    color: AppTheme.primary,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 14, color: AppTheme.primary),
            ],
          ),
        ),
      );
    } else {
      // Non-friends see a locked message
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(Icons.lock_outline, size: 12, color: AppTheme.textLight),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Add friend to see location',
                style: AppTheme.caption(size: 12, color: AppTheme.textLight),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Navigate to the linked marker on the map.
  Future<void> _navigateToMarker(String markerId) async {
    try {
      final markerDoc = await FirebaseFirestore.instance
          .collection('Markers')
          .doc(markerId)
          .get();

      if (markerDoc.exists && mounted) {
        final data = markerDoc.data()!;
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;

        if (lat != null && lng != null) {
          // Navigate to the map page with the marker location
          // For now, show a dialog with the location info
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(data['name'] ?? 'Location'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['description'] != null)
                      Text(data['description']),
                    const SizedBox(height: 8),
                    Text(
                      'Coordinates: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                      style: AppTheme.caption(size: 12, color: AppTheme.textMedium),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error navigating to marker: $e');
    }
  }

  Widget _buildInstructionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_list_numbered, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: AppTheme.heading(size: 18, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.recipe.steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTheme.body(
                          size: 14,
                          color: Colors.white,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: AppTheme.body(size: 14, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Comments',
                  style: AppTheme.heading(size: 16, color: AppTheme.textDark),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Streaming comments
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Recipes')
                .doc(widget.recipe.id)
                .collection('Comments')
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                );
              }

              final comments = snapshot.data?.docs ?? [];

              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 40,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No comments yet',
                          style: AppTheme.body(color: AppTheme.textMedium),
                        ),
                        Text(
                          'Be the first to comment!',
                          style: AppTheme.caption(color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = comments[index].data() as Map<String, dynamic>;
                  final createdAt = data['createdAt'] as Timestamp?;
                  final date = createdAt?.toDate() ?? DateTime.now();
                  final userEmail = data['userEmail'] as String? ?? '';

                  // Fetch current user data for up-to-date profile info
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getUserData(userEmail),
                    builder: (context, userSnapshot) {
                      // Use fetched data or fallback to stored comment data
                      final userData = userSnapshot.data ?? {};
                      final username = userData['username'] as String? ??
                          data['username'] as String? ??
                          userEmail.split('@')[0];
                      final profilePic = userData['profilePic'] as String? ??
                          data['profilePic'] as String?;

                      // Capitalize display name
                      final capitalizedName = username.split(' ').map((word) {
                        if (word.isEmpty) return word;
                        return word[0].toUpperCase() + word.substring(1).toLowerCase();
                      }).join(' ');

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                          foregroundImage: profilePic != null && profilePic.isNotEmpty
                              ? AssetImage('lib/assets/images/$profilePic')
                              : null,
                          child: profilePic == null || profilePic.isEmpty
                              ? Text(
                                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                                  style: AppTheme.body(
                                    size: 14,
                                    color: AppTheme.primary,
                                    weight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          capitalizedName,
                          style: AppTheme.body(
                            size: 13,
                            color: AppTheme.textDark,
                            weight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['text'] as String? ?? '',
                              style: AppTheme.body(size: 14, color: AppTheme.textDark),
                            ),
                            Text(
                              DateFormat('MMM d, y').format(date),
                              style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),

          const Divider(height: 1),

          // Comment input
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.borderRadiusSmall,
                        borderSide: BorderSide(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: AppTheme.body(size: 14, color: AppTheme.textDark),
                    maxLines: 2,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: AppTheme.primary),
                  onPressed: () {
                    final text = _commentController.text.trim();
                    if (text.isNotEmpty) {
                      _addComment(text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen image gallery with swipe navigation
class _FullScreenImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<_FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.image_not_supported,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
