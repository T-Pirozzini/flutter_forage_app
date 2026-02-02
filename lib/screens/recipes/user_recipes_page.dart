import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/data/models/recipe.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/recipes/add_recipe_page.dart';
import 'package:flutter_forager_app/screens/recipes/components/recipe_grid_card.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Page to display recipes created by the current user
class UserRecipesPage extends ConsumerWidget {
  const UserRecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final recipeRepo = ref.watch(recipeRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Recipes',
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
      ),
      body: StreamBuilder<List<Recipe>>(
        stream: recipeRepo.streamByUserEmail(currentUser!.email!),
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
                onRecipeUpdated: () {
                  // Force refresh by invalidating the stream
                },
              );
            },
          );
        },
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
