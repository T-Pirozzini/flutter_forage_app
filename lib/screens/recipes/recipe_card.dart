import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/recipe.dart';
import 'package:flutter_forager_app/screens/recipes/add_recipe_page.dart';
import 'package:flutter_forager_app/screens/recipes/comments_page.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback? onRecipeDeleted;

  const RecipeCard({required this.recipe, this.onRecipeDeleted, Key? key})
      : super(key: key);

  @override
  _RecipeCardState createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isExpanded = false;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.recipe.imageUrls.isNotEmpty
        ? (widget.recipe.imageUrls.length - 1) ~/ 2
        : 0;
    _pageController =
        PageController(viewportFraction: 0.8, initialPage: _currentPage);
    _checkOwnership();
  }

  @override
  void didUpdateWidget(RecipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check ownership if recipe changes
    if (oldWidget.recipe.id != widget.recipe.id ||
        oldWidget.recipe.userEmail != widget.recipe.userEmail) {
      _checkOwnership();
    }
  }

  void _checkOwnership() {
    final currentUser = FirebaseAuth.instance.currentUser;
    // Default to false if not logged in
    final isOwner = currentUser != null &&
        currentUser.email != null &&
        widget.recipe.userEmail == currentUser.email;
    if (mounted) {
      setState(() {
        _isOwner = isOwner;
      });
    }
  }

  Future<void> _deleteRecipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Recipe'),
        content: Text(
            'Are you sure you want to delete this recipe? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Double-check ownership before deleting
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null || currentUser.email != widget.recipe.userEmail) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only delete your own recipes')),
          );
          return;
        }

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

        // Delete images from storage
        for (final url in widget.recipe.imageUrls) {
          try {
            final ref =
                firebase_storage.FirebaseStorage.instance.refFromURL(url);
            await ref.delete();
          } catch (e) {
            print('Error deleting image: $e');
          }
        }

        // Notify parent widget
        if (widget.onRecipeDeleted != null) {
          widget.onRecipeDeleted!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recipe deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete recipe: $e')),
        );
      }
    }
  }

  void _navigateToEditPage() {
    // Double-check ownership before editing
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.email != widget.recipe.userEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only edit your own recipes')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecipePage(
          recipeToEdit: widget.recipe, // Pass the existing recipe
        ),
      ),
    ).then((_) {
      // Optional: Refresh the recipe if needed
      if (widget.onRecipeDeleted != null) {
        widget.onRecipeDeleted!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with recipe name and user info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.9),
                    AppTheme.secondary.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          widget.recipe.name,
                          style: AppTheme.heading(
                            size: 24,
                            color: AppTheme.textWhite,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isOwner)
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.white),
                              onPressed: _navigateToEditPage,
                              tooltip: 'Edit Recipe',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.white),
                              onPressed: _deleteRecipe,
                              tooltip: 'Delete Recipe',
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            widget.recipe.userName,
                            style: AppTheme.body(
                              size: 14,
                              color: AppTheme.textWhite,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat('MMM d, y').format(widget.recipe.timestamp),
                        style: AppTheme.caption(
                          size: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Image carousel
            if (widget.recipe.imageUrls.isNotEmpty)
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.recipe.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.recipe.imageUrls[index],
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                    ),
                    if (widget.recipe.imageUrls.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.recipe.imageUrls.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Container(
                height: 120,
                color: AppTheme.backgroundLight,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.no_photography,
                        size: 40, color: AppTheme.textMedium),
                    const SizedBox(height: 8),
                    Text(
                      'No images',
                      style: AppTheme.body(color: AppTheme.textMedium),
                    ),
                  ],
                ),
              ),

            // Ingredients section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingredients',
                    style: AppTheme.title(
                      size: 18,
                      weight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.recipe.ingredients.map((ingredient) {
                      return Chip(
                        label: Text(
                          '${ingredient.quantity} ${ingredient.name}',
                          style: AppTheme.body(size: 14),
                        ),
                        avatar: Icon(
                          ingredient.isForaged
                              ? Icons.eco
                              : Icons.shopping_basket,
                          size: 18,
                          color: ingredient.isForaged
                              ? AppTheme.success
                              : AppTheme.secondary,
                        ),
                        backgroundColor: AppTheme.backgroundLight,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Instructions section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ExpansionTile(
                title: Text(
                  'Instructions',
                  style: AppTheme.title(
                    size: 18,
                    weight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                initiallyExpanded: _isExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _isExpanded = expanded;
                  });
                },
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          widget.recipe.steps.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RichText(
                            text: TextSpan(
                              style: AppTheme.body(
                                size: 16,
                                color: AppTheme.textDark,
                              ),
                              children: [
                                TextSpan(
                                  text: '${entry.key + 1}. ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: entry.value),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Comments button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CommentsPage(recipe: widget.recipe),
                      ),
                    );
                  },
                  icon: const Icon(Icons.comment_outlined),
                  label: Text(
                    'View Comments',
                    style: AppTheme.title(
                      size: 14,
                      weight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                    ),
                    side: BorderSide(color: AppTheme.primary),
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
