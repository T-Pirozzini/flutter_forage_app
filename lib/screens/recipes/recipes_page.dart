import 'package:flutter/material.dart';
import 'package:flutter_forager_app/components/screen_heading.dart';
import 'package:flutter_forager_app/models/recipe.dart';
import 'package:flutter_forager_app/providers/recipe_provider.dart';
import 'package:flutter_forager_app/screens/recipes/recipe_card.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart' show AppColors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_recipe_page.dart';

class RecipesPage extends ConsumerWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeStream = ref.watch(recipeStreamProvider);

    return Scaffold(
      body: recipeStream.when(
        data: (recipes) {
          if (recipes.isEmpty) {
            return Center(child: Text('No recipes found.'));
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ScreenHeading(title: 'Recipes'),
              ),
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  color: AppColors.titleBarColor,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StyledText("Cook a meal with your foraged ingredients"),
                      StyledText('and share with the community!'),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final recipe = recipes[index];
                    return RecipeCard(recipe: recipe);
                  },
                  childCount: recipes.length,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: 100), // Add this to provide extra space
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          foregroundColor: Colors.white,
          backgroundColor: Colors.deepOrange,
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
