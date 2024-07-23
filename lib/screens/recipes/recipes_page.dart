import 'package:flutter/material.dart';
import 'package:flutter_forager_app/models/recipe.dart';
import 'package:flutter_forager_app/providers/recipe_provider.dart';
import 'package:flutter_forager_app/screens/recipes/recipe_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_recipe_page.dart';

class RecipesPage extends ConsumerWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeStream = ref.watch(recipeStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RECIPES'),
        titleTextStyle: GoogleFonts.philosopher(
            fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.5),
        centerTitle: true,
        backgroundColor: Colors.grey.shade600,
      ),
      body: recipeStream.when(
        data: (recipes) {
          if (recipes.isEmpty) {
            return Center(child: Text('No recipes found.'));
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  color: Colors.grey.shade300,
                  child: Column(
                    children: [
                      Text("Cook a meal with your foraged ingredients"),
                      Text('and share with the community!'),
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
