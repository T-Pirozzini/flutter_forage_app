import 'package:flutter_forager_app/models/recipe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// StreamProvider for fetching recipes
final recipeStreamProvider = StreamProvider<List<Recipe>>((ref) {
  return RecipeService().getRecipes();
});

// Provider for RecipeService to add recipes
final recipeServiceProvider = Provider<RecipeService>((ref) {
  return RecipeService();
});

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addRecipe(Recipe recipe) async {
    await _firestore.collection('Recipes').add(recipe.toMap());
  }

  Stream<List<Recipe>> getRecipes() {
    return _firestore
        .collection('Recipes')
        .orderBy('timestamp', descending: true) // Order by timestamp descending
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Recipe.fromMap(doc.id, data);
      }).toList();
    });
  }
}
