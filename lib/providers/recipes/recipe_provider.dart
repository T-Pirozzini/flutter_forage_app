import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/recipe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// StreamProvider for fetching all recipes using RecipeRepository
final recipeStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final recipeRepo = ref.watch(recipeRepositoryProvider);
  return recipeRepo.streamAllRecipes();
});

/// Provider for recipe operations (kept for backward compatibility)
/// Now uses RecipeRepository under the hood
final recipeServiceProvider = Provider((ref) {
  return ref.watch(recipeRepositoryProvider);
});
