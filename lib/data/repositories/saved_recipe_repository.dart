import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/data/models/recipe.dart';
import 'package:flutter_forager_app/data/models/saved_recipe.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';

/// Repository for managing user's saved/bookmarked recipes.
///
/// Uses Firestore subcollection for scalability:
/// - /Users/{userId}/SavedRecipes/{savedRecipeId}
///
/// Saved recipes denormalize recipe data for efficient display without additional lookups.
class SavedRecipeRepository {
  final FirestoreService firestoreService;

  SavedRecipeRepository({required this.firestoreService});

  /// Stream all saved recipes for a user
  Stream<List<SavedRecipeModel>> streamSavedRecipes(String userId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('SavedRecipes')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SavedRecipeModel.fromFirestore(doc)).toList();
    });
  }

  /// Get all saved recipes for a user (one-time fetch)
  Future<List<SavedRecipeModel>> getSavedRecipes(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('SavedRecipes')
        .orderBy('savedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => SavedRecipeModel.fromFirestore(doc)).toList();
  }

  /// Check if a recipe is saved by the user
  Future<bool> isSaved(String userId, String recipeId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('SavedRecipes')
        .where('recipeId', isEqualTo: recipeId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Stream saved status for a specific recipe
  Stream<bool> streamIsSaved(String userId, String recipeId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('SavedRecipes')
        .where('recipeId', isEqualTo: recipeId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Save a recipe
  ///
  /// Denormalizes recipe data for efficient display.
  Future<String> saveRecipe({
    required String userId,
    required Recipe recipe,
    String? notes,
  }) async {
    // Check if already saved
    if (await isSaved(userId, recipe.id)) {
      throw Exception('Recipe already saved');
    }

    final savedRecipe = SavedRecipeModel(
      id: '',
      recipeId: recipe.id,
      recipeName: recipe.name,
      recipeOwner: recipe.userEmail,
      recipeOwnerName: recipe.userName,
      primaryImageUrl: recipe.imageUrls.isNotEmpty ? recipe.imageUrls.first : null,
      foragedIngredientCount: recipe.foragedIngredientCount,
      savedAt: DateTime.now(),
      notes: notes,
    );

    final docRef = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('SavedRecipes')
        .add(savedRecipe.toMap());

    // Increment saveCount on the recipe
    await _incrementSaveCount(recipe.id);

    debugPrint('Recipe saved: ${recipe.id} for user $userId');
    return docRef.id;
  }

  /// Remove a saved recipe by saved recipe ID
  Future<void> unsaveRecipe(String userId, String savedRecipeId) async {
    // Get the saved recipe first to get the original recipe ID
    final doc = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('SavedRecipes')
        .doc(savedRecipeId)
        .get();

    if (doc.exists) {
      final recipeId = doc.data()?['recipeId'] as String?;

      await doc.reference.delete();

      // Decrement saveCount on the recipe
      if (recipeId != null) {
        await _decrementSaveCount(recipeId);
      }

      debugPrint('Saved recipe removed: $savedRecipeId for user $userId');
    }
  }

  /// Remove a saved recipe by recipe ID
  Future<void> unsaveRecipeByRecipeId(String userId, String recipeId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('SavedRecipes')
        .where('recipeId', isEqualTo: recipeId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // Decrement saveCount on the recipe
    await _decrementSaveCount(recipeId);

    debugPrint('Saved recipe removed for recipe: $recipeId');
  }

  /// Toggle save status for a recipe
  ///
  /// Returns true if recipe was saved, false if unsaved.
  Future<bool> toggleSave({
    required String userId,
    required Recipe recipe,
  }) async {
    final existing = await getSavedRecipeByRecipeId(userId, recipe.id);

    if (existing != null) {
      await unsaveRecipe(userId, existing.id);
      return false;
    } else {
      await saveRecipe(userId: userId, recipe: recipe);
      return true;
    }
  }

  /// Get saved recipe by recipe ID (if exists)
  Future<SavedRecipeModel?> getSavedRecipeByRecipeId(String userId, String recipeId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('SavedRecipes')
        .where('recipeId', isEqualTo: recipeId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return SavedRecipeModel.fromFirestore(snapshot.docs.first);
  }

  /// Update saved recipe notes
  Future<void> updateNotes(String userId, String savedRecipeId, String? notes) async {
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('SavedRecipes')
        .doc(savedRecipeId)
        .update({'notes': notes});
  }

  /// Get saved recipe count for a user
  Future<int> getSavedRecipeCount(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('SavedRecipes')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Search saved recipes by name
  Stream<List<SavedRecipeModel>> searchSavedRecipes(String userId, String query) {
    if (query.isEmpty) return streamSavedRecipes(userId);

    final queryLower = query.toLowerCase();

    return streamSavedRecipes(userId).map((recipes) {
      return recipes
          .where((recipe) =>
              recipe.recipeName.toLowerCase().contains(queryLower) ||
              recipe.recipeOwnerName.toLowerCase().contains(queryLower) ||
              (recipe.notes?.toLowerCase().contains(queryLower) ?? false))
          .toList();
    });
  }

  /// Increment save count on the original recipe document
  Future<void> _incrementSaveCount(String recipeId) async {
    try {
      await firestoreService.collection('Recipes').doc(recipeId).update({
        'saveCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing save count: $e');
    }
  }

  /// Decrement save count on the original recipe document
  Future<void> _decrementSaveCount(String recipeId) async {
    try {
      await firestoreService.collection('Recipes').doc(recipeId).update({
        'saveCount': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('Error decrementing save count: $e');
    }
  }

  /// Sync saved recipe data when recipe is updated
  ///
  /// Call this when a recipe's details change to update all saved copies.
  Future<void> syncSavedRecipeData({
    required String recipeId,
    required String recipeName,
    required String recipeOwnerName,
    String? primaryImageUrl,
    int? foragedIngredientCount,
  }) async {
    // This would typically be done via Cloud Functions for efficiency,
    // but for simplicity, we can log the request here.
    debugPrint('Saved recipe sync requested for recipe: $recipeId');
    // Note: In production, implement via Cloud Functions to update
    // all users' saved recipes when a recipe changes.
  }
}
