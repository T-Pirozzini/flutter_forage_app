import 'package:flutter_forager_app/models/recipe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart';

final recipeProvider = Provider<RecipeService>((ref) {
  return RecipeService();
});

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addRecipe(Recipe recipe) async {
    await _firestore.collection('Recipes').add(recipe.toMap());
  }
}
