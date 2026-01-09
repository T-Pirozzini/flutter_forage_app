import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/core/constants/firestore_collections.dart';
import 'package:flutter_forager_app/data/repositories/base_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';
import 'package:flutter_forager_app/data/models/recipe.dart';

/// Repository for managing Recipe data
///
/// Handles all CRUD operations for recipes including:
/// - Creating, reading, updating, and deleting recipes
/// - Querying recipes by user
/// - Managing likes
class RecipeRepository extends BaseRepository<Recipe> {
  RecipeRepository({required super.firestoreService})
      : super(collectionPath: FirestoreCollections.recipes);

  @override
  Recipe fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe.fromMap(doc.id, data);
  }

  @override
  Map<String, dynamic> toFirestore(Recipe model) {
    return model.toMap();
  }

  /// Get all recipes ordered by timestamp (newest first)
  Future<List<Recipe>> getAllRecipes() async {
    try {
      final snapshot = await firestoreService
          .collection(collectionPath)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream all recipes ordered by timestamp
  Stream<List<Recipe>> streamAllRecipes() {
    return firestoreService
        .collection(collectionPath)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Get recipes by user email
  Future<List<Recipe>> getByUserEmail(String userEmail) async {
    return queryByField('userEmail', userEmail);
  }

  /// Stream recipes by user email
  Stream<List<Recipe>> streamByUserEmail(String userEmail) {
    return streamQueryByField('userEmail', userEmail);
  }

  /// Get recipe count for a user
  Future<int> getRecipeCountByUser(String userEmail) async {
    try {
      final snapshot = await firestoreService
          .collection(collectionPath)
          .where('userEmail', isEqualTo: userEmail)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Toggle like on a recipe
  Future<void> toggleLike({
    required String recipeId,
    required String userEmail,
  }) async {
    try {
      final doc = await firestoreService
          .collection(collectionPath)
          .doc(recipeId)
          .get();

      if (!doc.exists) {
        throw Exception('Recipe not found');
      }

      final recipe = fromFirestore(doc);
      final isLiked = recipe.likes.contains(userEmail);

      if (isLiked) {
        // Unlike
        await update(recipeId, {
          'likes': FieldValue.arrayRemove([userEmail]),
        });
      } else {
        // Like
        await update(recipeId, {
          'likes': FieldValue.arrayUnion([userEmail]),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a recipe (with owner check)
  Future<void> deleteRecipe({
    required String recipeId,
    required String currentUserEmail,
  }) async {
    try {
      final doc = await firestoreService
          .collection(collectionPath)
          .doc(recipeId)
          .get();

      if (!doc.exists) {
        throw Exception('Recipe not found');
      }

      final recipe = fromFirestore(doc);
      if (recipe.userEmail != currentUserEmail) {
        throw Exception('You can only delete your own recipes');
      }

      await delete(recipeId);
    } catch (e) {
      rethrow;
    }
  }

  /// Search recipes by name
  Future<List<Recipe>> searchByName(String query) async {
    try {
      // Firestore doesn't support full-text search, so we fetch all and filter
      // For production, consider using Algolia or similar
      final allRecipes = await getAllRecipes();

      final lowerQuery = query.toLowerCase();
      return allRecipes.where((recipe) {
        return recipe.name.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
