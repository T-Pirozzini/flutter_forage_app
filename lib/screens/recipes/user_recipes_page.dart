import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/data/models/recipe.dart';
import 'package:flutter_forager_app/data/models/saved_recipe.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/recipes/add_recipe_page.dart';
import 'package:flutter_forager_app/screens/recipes/components/recipe_grid_card.dart';
import 'package:flutter_forager_app/screens/recipes/recipe_detail_screen.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Page to display user's created and saved recipes in tabs
class UserRecipesPage extends ConsumerStatefulWidget {
  /// Which tab to show initially (0 = My Recipes, 1 = Saved)
  final int initialTab;

  const UserRecipesPage({super.key, this.initialTab = 0});

  @override
  ConsumerState<UserRecipesPage> createState() => _UserRecipesPageState();
}

class _UserRecipesPageState extends ConsumerState<UserRecipesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser?.email == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Recipes'),
          backgroundColor: AppTheme.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: AppTheme.textLight),
              const SizedBox(height: 16),
              Text(
                'Please log in to view your recipes',
                style: AppTheme.body(color: AppTheme.textMedium),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recipes',
          style: AppTheme.heading(size: 18, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddRecipePage()),
              );
            },
            tooltip: 'Add Recipe',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: AppTheme.button(size: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.restaurant_menu, size: 20),
              text: 'My Recipes',
            ),
            Tab(
              icon: Icon(Icons.bookmark, size: 20),
              text: 'Saved',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyRecipesTab(userEmail: currentUser!.email!),
          _SavedRecipesTab(userEmail: currentUser.email!),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addUserRecipeButton',
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecipePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Tab showing user's created recipes
class _MyRecipesTab extends ConsumerWidget {
  final String userEmail;

  const _MyRecipesTab({required this.userEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeRepo = ref.watch(recipeRepositoryProvider);

    return StreamBuilder<List<Recipe>>(
      stream: recipeRepo.streamByUserEmail(userEmail),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading your recipes',
                  style: AppTheme.title(size: 16, color: AppTheme.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: AppTheme.caption(color: AppTheme.textMedium),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final recipes = snapshot.data ?? [];

        if (recipes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: AppTheme.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'No recipes yet',
                  style: AppTheme.title(size: 18, color: AppTheme.textMedium),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Share your foraged creations with the community!',
                    style: AppTheme.body(size: 14, color: AppTheme.textLight),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddRecipePage()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Recipe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return RecipeGridCard(
              recipe: recipe,
              onRecipeUpdated: () {},
            );
          },
        );
      },
    );
  }
}

/// Tab showing user's saved/bookmarked recipes
class _SavedRecipesTab extends ConsumerWidget {
  final String userEmail;

  const _SavedRecipesTab({required this.userEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedRecipeRepo = ref.watch(savedRecipeRepositoryProvider);

    return StreamBuilder<List<SavedRecipeModel>>(
      stream: savedRecipeRepo.streamSavedRecipes(userEmail),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading saved recipes',
                  style: AppTheme.title(size: 16, color: AppTheme.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: AppTheme.caption(color: AppTheme.textMedium),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final savedRecipes = snapshot.data ?? [];

        if (savedRecipes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_outline,
                  size: 64,
                  color: AppTheme.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved recipes yet',
                  style: AppTheme.title(size: 18, color: AppTheme.textMedium),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Browse recipes and tap the bookmark icon to save them here.',
                    style: AppTheme.body(size: 14, color: AppTheme.textLight),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: savedRecipes.length,
          itemBuilder: (context, index) {
            final savedRecipe = savedRecipes[index];
            return _SavedRecipeCard(
              savedRecipe: savedRecipe,
              onTap: () => _navigateToRecipe(context, ref, savedRecipe),
              onUnsave: () => _unsaveRecipe(context, ref, savedRecipe),
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToRecipe(
    BuildContext context,
    WidgetRef ref,
    SavedRecipeModel savedRecipe,
  ) async {
    final recipeRepo = ref.read(recipeRepositoryProvider);

    try {
      final recipe = await recipeRepo.getById(savedRecipe.recipeId);

      if (recipe != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe not found. It may have been deleted.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recipe: $e')),
        );
      }
    }
  }

  Future<void> _unsaveRecipe(
    BuildContext context,
    WidgetRef ref,
    SavedRecipeModel savedRecipe,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Saved Recipe'),
        content: Text(
          'Remove "${savedRecipe.recipeName}" from your saved recipes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final savedRecipeRepo = ref.read(savedRecipeRepositoryProvider);
      await savedRecipeRepo.unsaveRecipe(userEmail, savedRecipe.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe removed from saved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove recipe: $e')),
        );
      }
    }
  }
}

/// Card widget for displaying a saved recipe in the grid
class _SavedRecipeCard extends StatelessWidget {
  final SavedRecipeModel savedRecipe;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  const _SavedRecipeCard({
    required this.savedRecipe,
    required this.onTap,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');

    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.borderRadiusMedium,
      child: Card(
        elevation: 2,
        shadowColor: AppTheme.primary.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMedium,
          side: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with unsave button overlay
            Stack(
              children: [
                _buildImage(),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: onUnsave,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.bookmark_remove,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Recipe name
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: Text(
                savedRecipe.recipeName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.title(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(Icons.eco, size: 14, color: AppTheme.success),
                  const SizedBox(width: 3),
                  Text(
                    '${savedRecipe.foragedIngredientCount}',
                    style: AppTheme.caption(size: 12, color: AppTheme.textMedium),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                '@${savedRecipe.recipeOwnerName} • ${dateFormat.format(savedRecipe.savedAt)}',
                style: AppTheme.caption(size: 10, color: AppTheme.textMedium),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (savedRecipe.primaryImageUrl == null) {
      return Container(
        height: 100,
        width: double.infinity,
        color: AppTheme.surfaceLight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 32, color: AppTheme.textLight),
            const SizedBox(height: 4),
            Text(
              'No image',
              style: AppTheme.caption(size: 10, color: AppTheme.textLight),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 100,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: savedRecipe.primaryImageUrl!,
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
    );
  }
}
