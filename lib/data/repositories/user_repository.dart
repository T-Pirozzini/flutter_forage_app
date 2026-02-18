import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/core/constants/firestore_collections.dart';
import 'package:flutter_forager_app/data/repositories/base_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';
import 'package:flutter_forager_app/data/models/user.dart';

/// Repository for managing User data
///
/// This repository handles all CRUD operations for users and user-related actions
/// like friend requests, achievements, points, and subscriptions.
class UserRepository extends BaseRepository<UserModel> {
  UserRepository({required super.firestoreService})
      : super(collectionPath: FirestoreCollections.users);

  @override
  UserModel fromFirestore(DocumentSnapshot doc) {
    return UserModel.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(UserModel model) {
    return model.toMap();
  }

  // CUSTOM QUERIES

  /// Get user by email
  Future<UserModel?> getByEmail(String email) async {
    try {
      final users = await queryByField(FirestoreFields.email, email);
      return users.isNotEmpty ? users.first : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user by username
  Future<UserModel?> getByUsername(String username) async {
    try {
      final users = await queryByField(FirestoreFields.username, username);
      return users.isNotEmpty ? users.first : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Search users by username (partial match)
  Future<List<UserModel>> searchByUsername(String query) async {
    try {
      // Firestore doesn't support case-insensitive or partial string matching
      // For production, consider using Algolia or similar search service
      // For now, we fetch all users and filter in-memory
      final allUsers = await getAll();

      return allUsers.where((user) {
        return user.username.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get all users who are open to foraging together
  ///
  /// Returns users where openToForage = true, sorted by lastActive descending.
  Future<List<UserModel>> getUsersOpenToForage() async {
    try {
      final snapshot = await firestoreService
          .collection(collectionPath)
          .where('openToForage', isEqualTo: true)
          .orderBy('lastActive', descending: true)
          .get();

      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Update user's last active timestamp
  Future<void> updateLastActive(String userId) async {
    await update(userId, {
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  /// Set or update the user's primary forage location
  ///
  /// This is the location displayed on Discover cards to help foragers
  /// find others nearby. Users can edit this in their profile.
  ///
  /// [userId] - The user's email/ID
  /// [location] - Display string (e.g., "Portland, United States")
  /// [latitude] - Location latitude
  /// [longitude] - Location longitude
  Future<void> setPrimaryForageLocation({
    required String userId,
    required String location,
    required double latitude,
    required double longitude,
  }) async {
    await update(userId, {
      'primaryForageLocation': location,
      'primaryForageLatitude': latitude,
      'primaryForgeLongitude': longitude,
    });
  }

  /// Clear the user's primary forage location
  Future<void> clearPrimaryForageLocation(String userId) async {
    await update(userId, {
      'primaryForageLocation': FieldValue.delete(),
      'primaryForageLatitude': FieldValue.delete(),
      'primaryForgeLongitude': FieldValue.delete(),
    });
  }

  // GAMIFICATION METHODS

  /// Award points to a user
  Future<void> awardPoints(String userId, int points) async {
    try {
      await firestoreService.runTransaction((transaction) async {
        final userDoc = await transaction.get(
          firestoreService.collection(collectionPath).doc(userId),
        );

        if (!userDoc.exists) return;

        final user = fromFirestore(userDoc);
        final newPoints = user.points + points;
        final newLevel = _calculateLevel(newPoints);

        transaction.update(userDoc.reference, {
          'points': newPoints,
          'level': newLevel,
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Unlock an achievement for a user
  Future<void> unlockAchievement(String userId, String achievementId) async {
    await update(userId, {
      'achievements': FieldValue.arrayUnion([achievementId]),
    });
  }

  /// Update user's streak
  Future<void> updateStreak(String userId, int newStreak) async {
    try {
      await firestoreService.runTransaction((transaction) async {
        final userDoc = await transaction.get(
          firestoreService.collection(collectionPath).doc(userId),
        );

        if (!userDoc.exists) return;

        final user = fromFirestore(userDoc);
        final longestStreak = newStreak > user.longestStreak
            ? newStreak
            : user.longestStreak;

        transaction.update(userDoc.reference, {
          'currentStreak': newStreak,
          'longestStreak': longestStreak,
          'lastActivityDate': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Increment an activity stat
  Future<void> incrementActivityStat(String userId, String statKey) async {
    await update(userId, {
      'activityStats.$statKey': FieldValue.increment(1),
    });
  }

  // FRIEND MANAGEMENT

  /// Send a friend request
  Future<void> sendFriendRequest(String senderId, String recipientId) async {
    final batch = firestoreService.batch();

    // Add to sender's sent requests
    batch.update(
      firestoreService.collection(collectionPath).doc(senderId),
      {
        'sentFriendRequests.$recipientId': 'pending',
      },
    );

    // Add to recipient's friend requests
    batch.update(
      firestoreService.collection(collectionPath).doc(recipientId),
      {
        'friendRequests.$senderId': 'pending',
      },
    );

    await batch.commit();
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest(String userId, String friendId) async {
    final batch = firestoreService.batch();

    // Add to both users' friends lists
    batch.update(
      firestoreService.collection(collectionPath).doc(userId),
      {
        'friends': FieldValue.arrayUnion([friendId]),
        'friendRequests.$friendId': FieldValue.delete(),
      },
    );

    batch.update(
      firestoreService.collection(collectionPath).doc(friendId),
      {
        'friends': FieldValue.arrayUnion([userId]),
        'sentFriendRequests.$userId': FieldValue.delete(),
      },
    );

    await batch.commit();
  }

  /// Reject a friend request
  Future<void> rejectFriendRequest(String userId, String requesterId) async {
    final batch = firestoreService.batch();

    // Remove from user's friend requests
    batch.update(
      firestoreService.collection(collectionPath).doc(userId),
      {
        'friendRequests.$requesterId': FieldValue.delete(),
      },
    );

    // Remove from requester's sent requests
    batch.update(
      firestoreService.collection(collectionPath).doc(requesterId),
      {
        'sentFriendRequests.$userId': FieldValue.delete(),
      },
    );

    await batch.commit();
  }

  /// Remove a friend
  Future<void> removeFriend(String userId, String friendId) async {
    final batch = firestoreService.batch();

    batch.update(
      firestoreService.collection(collectionPath).doc(userId),
      {
        'friends': FieldValue.arrayRemove([friendId]),
      },
    );

    batch.update(
      firestoreService.collection(collectionPath).doc(friendId),
      {
        'friends': FieldValue.arrayRemove([userId]),
      },
    );

    await batch.commit();
  }

  // SAVED CONTENT

  /// Save a location to user's bookmarks
  Future<void> saveLocation(String userId, String locationId) async {
    await update(userId, {
      'savedLocations': FieldValue.arrayUnion([locationId]),
    });
  }

  /// Remove a location from user's bookmarks
  Future<void> unsaveLocation(String userId, String locationId) async {
    await update(userId, {
      'savedLocations': FieldValue.arrayRemove([locationId]),
    });
  }

  /// Save a recipe to user's collection
  Future<void> saveRecipe(String userId, String recipeId) async {
    await update(userId, {
      'savedRecipes': FieldValue.arrayUnion([recipeId]),
    });
  }

  /// Remove a recipe from user's collection
  Future<void> unsaveRecipe(String userId, String recipeId) async {
    await update(userId, {
      'savedRecipes': FieldValue.arrayRemove([recipeId]),
    });
  }

  // ONBOARDING & PREMIUM

  /// Mark onboarding as completed
  Future<void> completeOnboarding(String userId, {String? appVersion}) async {
    final updates = <String, dynamic>{
      'hasCompletedOnboarding': true,
    };
    if (appVersion != null) {
      updates['lastSeenTutorialVersion'] = appVersion;
    }
    await update(userId, updates);
  }

  /// Mark the tutorial/what's-new as seen for a specific app version.
  Future<void> markTutorialVersionSeen(String userId, String version) async {
    await update(userId, {
      'hasCompletedOnboarding': true,
      'lastSeenTutorialVersion': version,
    });
  }

  /// Update subscription status
  Future<void> updateSubscription({
    required String userId,
    required String tier,
    DateTime? expiry,
  }) async {
    final updates = <String, dynamic>{
      'subscriptionTier': tier,
    };

    if (expiry != null) {
      updates['subscriptionExpiry'] = Timestamp.fromDate(expiry);
    }

    await update(userId, updates);
  }

  // HELPER METHODS

  /// Calculate level based on points (100 points per level)
  int _calculateLevel(int points) {
    return (points / 100).floor() + 1;
  }
}
