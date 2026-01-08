import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/core/constants/firestore_collections.dart';
import 'package:flutter_forager_app/data/repositories/base_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';
import 'package:flutter_forager_app/data/models/post.dart';

/// Repository for managing Post (Community) data
///
/// Handles all CRUD operations for community posts including:
/// - Creating and deleting posts
/// - Adding comments
/// - Updating status
/// - Managing likes and bookmarks
class PostRepository extends BaseRepository<PostModel> {
  PostRepository({required super.firestoreService})
      : super(collectionPath: FirestoreCollections.posts);

  @override
  PostModel fromFirestore(DocumentSnapshot doc) {
    return PostModel.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(PostModel model) {
    // Posts don't have a toMap method in the model, so we construct it here
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
      'likedBy': model.likedBy,
      'bookmarkCount': model.bookmarkCount,
      'bookmarkedBy': model.bookmarkedBy,
      'commentCount': model.commentCount,
      'originalMarkerOwner': model.originalMarkerOwner,
      'comments': model.comments,
      'currentStatus': model.currentStatus,
      'statusHistory': model.statusHistory,
    };
  }

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

  /// Get posts by user email
  Future<List<PostModel>> getByUserEmail(String userEmail) async {
    return queryByField('userEmail', userEmail);
  }

  /// Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userEmail,
    required String username,
    required String text,
  }) async {
    final commentData = {
      'userId': userId,
      'userEmail': userEmail,
      'username': username,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await update(postId, {
      'comments': FieldValue.arrayUnion([commentData]),
      'commentCount': FieldValue.increment(1),
    });
  }

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

  /// Toggle like on a post
  Future<void> toggleLike({
    required String postId,
    required String userEmail,
    required bool isCurrentlyLiked,
  }) async {
    if (isCurrentlyLiked) {
      await update(postId, {
        'likedBy': FieldValue.arrayRemove([userEmail]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await update(postId, {
        'likedBy': FieldValue.arrayUnion([userEmail]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  /// Toggle bookmark on a post
  Future<void> toggleBookmark({
    required String postId,
    required String userEmail,
    required bool isCurrentlyBookmarked,
  }) async {
    if (isCurrentlyBookmarked) {
      await update(postId, {
        'bookmarkedBy': FieldValue.arrayRemove([userEmail]),
        'bookmarkCount': FieldValue.increment(-1),
      });
    } else {
      await update(postId, {
        'bookmarkedBy': FieldValue.arrayUnion([userEmail]),
        'bookmarkCount': FieldValue.increment(1),
      });
    }
  }

  /// Delete a post (with owner check)
  Future<void> deletePost({
    required String postId,
    required String currentUserEmail,
    required String postOwnerEmail,
  }) async {
    if (currentUserEmail != postOwnerEmail) {
      throw Exception('You can only delete your own posts');
    }
    await delete(postId);
  }
}
