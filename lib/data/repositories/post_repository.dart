import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/core/constants/firestore_collections.dart';
import 'package:flutter_forager_app/data/repositories/base_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';
import 'package:flutter_forager_app/data/models/post.dart';
import 'package:flutter_forager_app/data/models/post_comment.dart';
import 'package:flutter_forager_app/data/models/post_like.dart';

/// Repository for managing Post (Community) data
///
/// Architecture:
/// - /Posts/{postId} - Main post document with denormalized counts
/// - /Posts/{postId}/Likes/{likeId} - Individual likes (scalable)
/// - /Posts/{postId}/Comments/{commentId} - Individual comments (scalable)
///
/// This architecture allows for:
/// - Unlimited likes/comments per post
/// - Pagination of comments
/// - Efficient queries (who liked, recent comments)
/// - Real-time updates on specific comments
class PostRepository extends BaseRepository<PostModel> {
  PostRepository({required super.firestoreService})
      : super(collectionPath: FirestoreCollections.posts);

  @override
  PostModel fromFirestore(DocumentSnapshot doc) {
    return PostModel.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(PostModel model) {
    return {
      'name': model.name,
      'description': model.description,
      'type': model.type,
      'images': model.imageUrls,
      'userEmail': model.userEmail,
      'postTimestamp': Timestamp.fromDate(model.postTimestamp),
      'location': {
        'latitude': model.latitude,
        'longitude': model.longitude,
      },
      'likeCount': model.likeCount,
      'bookmarkCount': model.bookmarkCount,
      'commentCount': model.commentCount,
      'originalMarkerOwner': model.originalMarkerOwner,
      'currentStatus': model.currentStatus,
      'statusHistory': model.statusHistory,
      // Note: likedBy, bookmarkedBy, comments arrays are deprecated
      // but kept for backward compatibility during migration
      'likedBy': model.likedBy,
      'bookmarkedBy': model.bookmarkedBy,
      'comments': model.comments,
    };
  }

  // ============== POST QUERIES ==============

  /// Stream all posts ordered by timestamp (newest first)
  Stream<List<PostModel>> streamAllPosts() {
    return firestoreService
        .collection(collectionPath)
        .orderBy('postTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Stream posts with pagination
  Stream<List<PostModel>> streamPostsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    Query query = firestoreService
        .collection(collectionPath)
        .orderBy('postTimestamp', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Get posts by user email
  Future<List<PostModel>> getByUserEmail(String userEmail) async {
    return queryByField('userEmail', userEmail);
  }

  /// Stream posts by type (for filtering)
  Stream<List<PostModel>> streamPostsByType(String type) {
    return firestoreService
        .collection(collectionPath)
        .where('type', isEqualTo: type)
        .orderBy('postTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  // ============== FILTERED QUERIES ==============

  /// Stream posts from friends only
  ///
  /// Note: Firestore whereIn has a limit of 30 items, so for users with
  /// more than 30 friends, we only filter by the first 30.
  Stream<List<PostModel>> streamFriendsPosts(List<String> friendEmails) {
    if (friendEmails.isEmpty) {
      return Stream.value([]);
    }

    // Firestore whereIn limit is 30
    final limitedEmails = friendEmails.take(30).toList();

    return firestoreService
        .collection(collectionPath)
        .where('userEmail', whereIn: limitedEmails)
        .orderBy('postTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Stream posts from followed users only
  ///
  /// Note: Firestore whereIn has a limit of 30 items, so for users following
  /// more than 30 people, we only filter by the first 30.
  Stream<List<PostModel>> streamFollowingPosts(List<String> followingEmails) {
    if (followingEmails.isEmpty) {
      return Stream.value([]);
    }

    // Firestore whereIn limit is 30
    final limitedEmails = followingEmails.take(30).toList();

    return firestoreService
        .collection(collectionPath)
        .where('userEmail', whereIn: limitedEmails)
        .orderBy('postTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Stream posts near a location (client-side filtering)
  ///
  /// Note: For simplicity, this fetches all posts and filters client-side.
  /// For production at scale, consider using GeoFirestore or geohashing.
  Stream<List<PostModel>> streamNearbyPosts(
    double lat,
    double lng,
    double radiusKm,
  ) {
    return streamAllPosts().map((posts) {
      return posts.where((post) {
        final distance = _calculateDistanceKm(
          lat,
          lng,
          post.latitude,
          post.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    });
  }

  /// Calculate distance between two points in kilometers using Haversine formula
  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }

  // ============== LIKES (SUBCOLLECTION) ==============

  /// Toggle like on a post using subcollection
  Future<bool> toggleLike({
    required String postId,
    required String userEmail,
    required bool isCurrentlyLiked,
  }) async {
    final likesRef = firestoreService
        .collection(collectionPath)
        .doc(postId)
        .collection('Likes');

    if (isCurrentlyLiked) {
      // Remove like
      final likeDoc = await likesRef.doc(userEmail).get();
      if (likeDoc.exists) {
        await likeDoc.reference.delete();
      }
      // Update count
      await update(postId, {
        'likeCount': FieldValue.increment(-1),
        // Also update legacy array for backward compatibility
        'likedBy': FieldValue.arrayRemove([userEmail]),
      });
      return false;
    } else {
      // Add like
      await likesRef.doc(userEmail).set({
        'userEmail': userEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Update count
      await update(postId, {
        'likeCount': FieldValue.increment(1),
        // Also update legacy array for backward compatibility
        'likedBy': FieldValue.arrayUnion([userEmail]),
      });
      return true;
    }
  }

  /// Check if user has liked a post
  Future<bool> hasUserLiked(String postId, String userEmail) async {
    final likeDoc = await firestoreService
        .collection(collectionPath)
        .doc(postId)
        .collection('Likes')
        .doc(userEmail)
        .get();
    return likeDoc.exists;
  }

  /// Stream like status for a user
  Stream<bool> streamUserLikeStatus(String postId, String userEmail) {
    return firestoreService
        .collection(collectionPath)
        .doc(postId)
        .collection('Likes')
        .doc(userEmail)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get all users who liked a post (with pagination)
  Future<List<PostLikeModel>> getLikes(String postId, {int limit = 50}) async {
    final snapshot = await firestoreService
        .collection(collectionPath)
        .doc(postId)
        .collection('Likes')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => PostLikeModel.fromFirestore(doc)).toList();
  }

  // ============== COMMENTS (SUBCOLLECTION) ==============

  /// Add a comment to a post using subcollection
  Future<String> addComment({
    required String postId,
    required String userId,
    required String userEmail,
    required String username,
    required String text,
    String? profilePic,
  }) async {
    final commentsRef = firestoreService
        .collection(collectionPath)
        .doc(postId)
        .collection('Comments');

    final comment = PostCommentModel(
      id: '',
      userId: userId,
      userEmail: userEmail,
      username: username,
      profilePic: profilePic,
      text: text,
      createdAt: DateTime.now(),
    );

    final docRef = await commentsRef.add(comment.toMap());

    // Update count on parent
    await update(postId, {
      'commentCount': FieldValue.increment(1),
    });

    debugPrint('Comment added to post $postId');
    return docRef.id;
  }

  /// Stream comments for a post (real-time, newest first)
  Stream<List<PostCommentModel>> streamComments(String postId, {int limit = 50}) {
    return firestoreService
        .collection(collectionPath)
        .doc(postId)
        .collection('Comments')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostCommentModel.fromFirestore(doc)).toList();
    });
  }

  /// Get comments with pagination
  Future<List<PostCommentModel>> getCommentsPaginated(
    String postId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = firestoreService
        .collection(collectionPath)
        .doc(postId)
        .collection('Comments')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => PostCommentModel.fromFirestore(doc)).toList();
  }

  /// Delete a comment
  Future<void> deleteComment(String postId, String commentId) async {
    await firestoreService
        .collection(collectionPath)
        .doc(postId)
        .collection('Comments')
        .doc(commentId)
        .delete();

    // Update count on parent
    await update(postId, {
      'commentCount': FieldValue.increment(-1),
    });

    debugPrint('Comment $commentId deleted from post $postId');
  }

  // ============== BOOKMARKS (HYBRID) ==============

  /// Toggle bookmark on a post
  /// Also syncs with user's Bookmarks subcollection (done in community_page.dart)
  Future<bool> toggleBookmark({
    required String postId,
    required String userEmail,
    required bool isCurrentlyBookmarked,
  }) async {
    if (isCurrentlyBookmarked) {
      await update(postId, {
        'bookmarkedBy': FieldValue.arrayRemove([userEmail]),
        'bookmarkCount': FieldValue.increment(-1),
      });
      return false;
    } else {
      await update(postId, {
        'bookmarkedBy': FieldValue.arrayUnion([userEmail]),
        'bookmarkCount': FieldValue.increment(1),
      });
      return true;
    }
  }

  // ============== STATUS ==============

  /// Update post status
  Future<void> updateStatus({
    required String postId,
    required String status,
    required String userId,
    required String userEmail,
    required String username,
    String? notes,
  }) async {
    final statusUpdate = {
      'status': status,
      'userId': userId,
      'userEmail': userEmail,
      'username': username,
      'timestamp': FieldValue.serverTimestamp(),
      if (notes?.isNotEmpty == true) 'notes': notes,
    };

    await update(postId, {
      'currentStatus': status,
      'statusHistory': FieldValue.arrayUnion([statusUpdate]),
    });
  }

  // ============== DELETE ==============

  /// Delete a post (with owner check)
  /// Also deletes all subcollections (likes, comments)
  Future<void> deletePost({
    required String postId,
    required String currentUserEmail,
    required String postOwnerEmail,
  }) async {
    if (currentUserEmail != postOwnerEmail) {
      throw Exception('You can only delete your own posts');
    }

    // Delete all likes
    final likesSnapshot = await firestoreService
        .collection(collectionPath)
        .doc(postId)
        .collection('Likes')
        .get();
    for (final doc in likesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete all comments
    final commentsSnapshot = await firestoreService
        .collection(collectionPath)
        .doc(postId)
        .collection('Comments')
        .get();
    for (final doc in commentsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete the post itself
    await delete(postId);

    debugPrint('Post $postId and all subcollections deleted');
  }

  // ============== MIGRATION ==============

  /// Migrate a single post from array-based to subcollection-based
  /// Call this for each existing post during migration
  Future<void> migratePostToSubcollections(String postId) async {
    final postDoc = await firestoreService.collection(collectionPath).doc(postId).get();
    if (!postDoc.exists) return;

    final data = postDoc.data() as Map<String, dynamic>;

    // Migrate likes
    final likedBy = List<String>.from(data['likedBy'] ?? []);
    for (final userEmail in likedBy) {
      await firestoreService
          .collection(collectionPath)
          .doc(postId)
          .collection('Likes')
          .doc(userEmail)
          .set({
        'userEmail': userEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Migrate comments
    final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
    for (final comment in comments) {
      await firestoreService
          .collection(collectionPath)
          .doc(postId)
          .collection('Comments')
          .add({
        'userId': comment['userId'] ?? '',
        'userEmail': comment['userEmail'] ?? '',
        'username': comment['username'] ?? '',
        'profilePic': comment['profilePic'],
        'text': comment['text'] ?? '',
        'createdAt': comment['timestamp'] ?? FieldValue.serverTimestamp(),
      });
    }

    debugPrint('Migrated post $postId: ${likedBy.length} likes, ${comments.length} comments');
  }

  /// Migrate all posts (run once)
  Future<int> migrateAllPosts() async {
    final snapshot = await firestoreService.collection(collectionPath).get();
    int migrated = 0;

    for (final doc in snapshot.docs) {
      await migratePostToSubcollections(doc.id);
      migrated++;
    }

    debugPrint('Migration complete: $migrated posts migrated');
    return migrated;
  }
}
