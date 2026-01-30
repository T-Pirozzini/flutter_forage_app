import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/data/models/following.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';

/// Repository for managing one-way follow relationships.
///
/// Unlike Friends (mutual/bidirectional), Following is one-way:
/// - User A can follow User B without B following A
/// - Used for filtering posts/recipes by followed users
///
/// Uses Firestore subcollection:
/// - /Users/{userId}/Following/{targetEmail}
class FollowingRepository {
  final FirestoreService firestoreService;

  FollowingRepository({required this.firestoreService});

  // ============ FOLLOWING MANAGEMENT ============

  /// Stream all users that the current user is following
  Stream<List<FollowingModel>> streamFollowing(String userId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Following')
        .orderBy('followedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FollowingModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get all users that the current user is following (one-time fetch)
  Future<List<FollowingModel>> getFollowing(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Following')
        .orderBy('followedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FollowingModel.fromFirestore(doc))
        .toList();
  }

  /// Get list of followed user emails (for filtering queries)
  Future<List<String>> getFollowingEmails(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Following')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// Check if the user is following another user
  Future<bool> isFollowing(String userId, String targetEmail) async {
    final doc = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Following')
        .doc(targetEmail)
        .get();

    return doc.exists;
  }

  /// Stream whether the user is following another user
  Stream<bool> streamIsFollowing(String userId, String targetEmail) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Following')
        .doc(targetEmail)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Follow a user (one-way relationship)
  Future<void> follow({
    required String userId,
    required String targetEmail,
    required String targetDisplayName,
    String? targetPhotoUrl,
  }) async {
    final following = FollowingModel(
      followedEmail: targetEmail,
      displayName: targetDisplayName,
      photoUrl: targetPhotoUrl,
      followedAt: DateTime.now(),
    );

    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Following')
        .doc(targetEmail)
        .set(following.toMap());

    debugPrint('Now following: $userId -> $targetEmail');
  }

  /// Unfollow a user
  Future<void> unfollow(String userId, String targetEmail) async {
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Following')
        .doc(targetEmail)
        .delete();

    debugPrint('Unfollowed: $userId -> $targetEmail');
  }

  /// Toggle follow status (returns new following state)
  Future<bool> toggleFollow({
    required String userId,
    required String targetEmail,
    required String targetDisplayName,
    String? targetPhotoUrl,
  }) async {
    final currentlyFollowing = await isFollowing(userId, targetEmail);

    if (currentlyFollowing) {
      await unfollow(userId, targetEmail);
      return false;
    } else {
      await follow(
        userId: userId,
        targetEmail: targetEmail,
        targetDisplayName: targetDisplayName,
        targetPhotoUrl: targetPhotoUrl,
      );
      return true;
    }
  }

  // ============ HELPERS ============

  /// Get count of users being followed
  Future<int> getFollowingCount(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Following')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Get count of users following the given user (followers)
  ///
  /// Note: This requires querying across all users' Following subcollections,
  /// which is inefficient. For production, consider maintaining a Followers
  /// subcollection or a follower count field on the user document.
  Future<int> getFollowerCount(String targetEmail) async {
    // This is a simplified implementation
    // For production, you'd want to maintain a denormalized count
    final snapshot = await firestoreService
        .collectionGroup('Following')
        .where('followedEmail', isEqualTo: targetEmail)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Search following list by display name
  Stream<List<FollowingModel>> searchFollowing(String userId, String query) {
    if (query.isEmpty) return streamFollowing(userId);

    final queryLower = query.toLowerCase();

    return streamFollowing(userId).map((following) {
      return following
          .where((user) =>
              user.displayName.toLowerCase().contains(queryLower) ||
              user.followedEmail.toLowerCase().contains(queryLower))
          .toList();
    });
  }
}
