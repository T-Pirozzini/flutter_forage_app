import 'package:flutter/material.dart';
import 'package:flutter_forager_app/shared/screen_heading.dart';
import 'package:flutter_forager_app/data/models/recipe.dart';
import 'package:flutter_forager_app/providers/recipes/recipe_provider.dart';
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
                      StyledTextMedium(
                        "Cook a meal with your foraged ingredients",
                        color: AppColors.textColor,
                      ),
                      StyledTextMedium('and share with the community!',
                          color: AppColors.textColor),
                      Row(
                        children: [
                          StyledTextMedium('Foraged:',
                              color: AppColors.textColor),
                          SizedBox(width: 4),
                          Icon(
                            Icons.eco,
                            color: Colors.green,
                            size: 18,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          StyledTextMedium('Purchased:',
                              color: AppColors.textColor),
                          SizedBox(width: 4),
                          Icon(Icons.shopping_basket,
                              color: Colors.orangeAccent, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final recipe = recipes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: RecipeCard(recipe: recipe),
                    );
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
