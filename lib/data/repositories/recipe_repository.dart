import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/core/constants/firestore_collections.dart';
import 'package:flutter_forager_app/data/repositories/base_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';
import 'package:flutter_forager_app/data/models/recipe.dart';
import 'package:flutter_forager_app/data/models/recipe_like.dart';

/// Repository for managing Recipe data
///
/// Architecture:
/// - /Recipes/{recipeId} - Main recipe document with denormalized counts
/// - /Recipes/{recipeId}/Likes/{userEmail} - Individual likes (scalable)
/// - /Recipes/{recipeId}/Comments/{commentId} - Individual comments (existing)
///
/// Handles all CRUD operations for recipes including:
/// - Creating, reading, updating, and deleting recipes
/// - Querying recipes by user
/// - Managing likes via subcollection
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

  // ============== LIKES (SUBCOLLECTION) ==============

  /// Toggle like on a recipe using subcollection
  ///
  /// Returns true if liked, false if unliked.
  Future<bool> toggleLike({
    required String recipeId,
    required String userEmail,
    required bool isCurrentlyLiked,
  }) async {
    final likesRef = firestoreService
        .collection(collectionPath)
        .doc(recipeId)
        .collection('Likes');

    if (isCurrentlyLiked) {
      // Remove like
      final likeDoc = await likesRef.doc(userEmail).get();
      if (likeDoc.exists) {
        await likeDoc.reference.delete();
      }
      // Update count and legacy array
      await update(recipeId, {
        'likeCount': FieldValue.increment(-1),
        'likes': FieldValue.arrayRemove([userEmail]),
      });
      debugPrint('Recipe $recipeId unliked by $userEmail');
      return false;
    } else {
      // Add like
      await likesRef.doc(userEmail).set({
        'userEmail': userEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Update count and legacy array
      await update(recipeId, {
        'likeCount': FieldValue.increment(1),
        'likes': FieldValue.arrayUnion([userEmail]),
      });
      debugPrint('Recipe $recipeId liked by $userEmail');
      return true;
    }
  }

  /// Check if user has liked a recipe
  Future<bool> hasUserLiked(String recipeId, String userEmail) async {
    final likeDoc = await firestoreService
        .collection(collectionPath)
        .doc(recipeId)
        .collection('Likes')
        .doc(userEmail)
        .get();
    return likeDoc.exists;
  }

  /// Stream like status for a user on a recipe
  Stream<bool> streamUserLikeStatus(String recipeId, String userEmail) {
    return firestoreService
        .collection(collectionPath)
        .doc(recipeId)
        .collection('Likes')
        .doc(userEmail)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get all users who liked a recipe (with pagination)
  Future<List<RecipeLikeModel>> getLikes(String recipeId, {int limit = 50}) async {
    final snapshot = await firestoreService
        .collection(collectionPath)
        .doc(recipeId)
        .collection('Likes')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => RecipeLikeModel.fromFirestore(doc)).toList();
  }

  /// Get like count for a recipe
  Future<int> getLikeCount(String recipeId) async {
    final snapshot = await firestoreService
        .collection(collectionPath)
        .doc(recipeId)
        .collection('Likes')
        .count()
        .get();

    return snapshot.count ?? 0;
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

  // ============== MIGRATION ==============

  /// Migrate a single recipe from array-based likes to subcollection-based
  Future<void> migrateRecipeToSubcollections(String recipeId) async {
    final recipeDoc = await firestoreService.collection(collectionPath).doc(recipeId).get();
    if (!recipeDoc.exists) return;

    final data = recipeDoc.data() as Map<String, dynamic>;

    // Migrate likes array to subcollection
    final likes = List<String>.from(data['likes'] ?? []);
    for (final userEmail in likes) {
      await firestoreService
          .collection(collectionPath)
          .doc(recipeId)
          .collection('Likes')
          .doc(userEmail)
          .set({
        'userEmail': userEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Ensure likeCount is set correctly
    await update(recipeId, {
      'likeCount': likes.length,
    });

    debugPrint('Migrated recipe $recipeId: ${likes.length} likes');
  }

  /// Migrate all recipes (run once)
  Future<int> migrateAllRecipes() async {
    final snapshot = await firestoreService.collection(collectionPath).get();
    int migrated = 0;

    for (final doc in snapshot.docs) {
      await migrateRecipeToSubcollections(doc.id);
      migrated++;
    }

    debugPrint('Recipe migration complete: $migrated recipes migrated');
    return migrated;
  }
}
