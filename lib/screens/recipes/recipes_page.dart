import 'package:flutter/material.dart';
import 'package:flutter_forager_app/providers/recipes/recipe_provider.dart';
import 'package:flutter_forager_app/screens/recipes/components/recipe_grid_card.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_recipe_page.dart';

class RecipesPage extends ConsumerWidget {
  const RecipesPage({super.key});

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
        title: Row(
          children: [
            Icon(Icons.restaurant_menu, color: AppTheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'About Recipes',
              style: AppTheme.heading(size: 18, color: AppTheme.primary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cook a meal with your foraged ingredients and share with the community!',
              style: AppTheme.body(size: 14, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.eco, color: AppTheme.success, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Foraged ingredients',
                  style: AppTheme.body(size: 14, color: AppTheme.textDark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.shopping_basket, color: AppTheme.secondary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Purchased ingredients',
                  style: AppTheme.body(size: 14, color: AppTheme.textDark),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: AppTheme.body(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeStream = ref.watch(recipeStreamProvider);

    return Scaffold(
      body: recipeStream.when(
        data: (recipes) {
          return CustomScrollView(
            slivers: [
              // Header with info icon
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          color: AppTheme.primary,
                        ),
                        onPressed: () => _showInfoDialog(context),
                        tooltip: 'About Recipes',
                      ),
                    ],
                  ),
                ),
              ),

              // Empty state or grid
              if (recipes.isEmpty)
                SliverFillRemaining(
                  child: Center(
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
                          style: AppTheme.title(
                            size: 18,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first recipe!',
                          style: AppTheme.body(
                            size: 14,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // 2-column grid of recipe cards
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75, // Taller cards for recipe content
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final recipe = recipes[index];
                        return RecipeGridCard(
                          recipe: recipe,
                          onRecipeUpdated: () {
                            ref.invalidate(recipeStreamProvider);
                          },
                        );
                      },
                      childCount: recipes.length,
                    ),
                  ),
                ),

              // Bottom padding for FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(
                'Error loading recipes',
                style: AppTheme.title(size: 16, color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: AppTheme.caption(color: AppTheme.textMedium),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          heroTag: 'addRecipeButton',
          foregroundColor: Colors.white,
          backgroundColor: AppTheme.accent,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddRecipePage()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
