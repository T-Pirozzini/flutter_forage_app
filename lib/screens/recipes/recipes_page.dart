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
    final recipeStream = ref.watch(recipeProvider).getRecipes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('RECIPES'),
        titleTextStyle: GoogleFonts.philosopher(
            fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.5),
        centerTitle: true,
        backgroundColor: Colors.grey.shade600,
      ),
      body: StreamBuilder<List<Recipe>>(
        stream: recipeStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No recipes found.'));
          }

          final recipes = snapshot.data!;

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return RecipeCard(recipe: recipe);
            },
          );
        },
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
