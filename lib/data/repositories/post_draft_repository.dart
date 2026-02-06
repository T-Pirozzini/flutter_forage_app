import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/data/models/post_draft.dart';

/// Repository for managing post drafts and scheduled posts
///
/// Drafts are stored in `/Users/{userId}/PostDrafts/{draftId}`
class PostDraftRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the drafts collection for a user
  CollectionReference<Map<String, dynamic>> _draftsCollection(String userId) {
    return _firestore.collection('Users').doc(userId).collection('PostDrafts');
  }

  /// Stream all drafts for a user
  Stream<List<PostDraftModel>> streamDrafts(String userId) {
    return _draftsCollection(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostDraftModel.fromFirestore(doc)).toList();
    });
  }

  /// Stream only unpublished drafts (draft or scheduled status)
  Stream<List<PostDraftModel>> streamUnpublishedDrafts(String userId) {
    return _draftsCollection(userId)
        .where('status', whereIn: ['draft', 'scheduled'])
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostDraftModel.fromFirestore(doc)).toList();
    });
  }

  /// Get a single draft by ID
  Future<PostDraftModel?> getDraft(String userId, String draftId) async {
    try {
      final doc = await _draftsCollection(userId).doc(draftId).get();
      if (!doc.exists) return null;
      return PostDraftModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting draft: $e');
      return null;
    }
  }

  /// Create a new draft
  Future<String> createDraft({
    required String userId,
    required String markerId,
    String? markerName,
    String? markerType,
    String? communityDescription,
    DateTime? scheduledFor,
  }) async {
    try {
      final now = DateTime.now();
      final status = scheduledFor != null
          ? PostDraftStatus.scheduled
          : PostDraftStatus.draft;

      final draft = PostDraftModel(
        id: '', // Will be set by Firestore
        markerId: markerId,
        markerName: markerName,
        markerType: markerType,
        communityDescription: communityDescription,
        scheduledFor: scheduledFor,
        status: status,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _draftsCollection(userId).add(draft.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating draft: $e');
      rethrow;
    }
  }

  /// Update an existing draft
  Future<void> updateDraft({
    required String userId,
    required String draftId,
    String? communityDescription,
    DateTime? scheduledFor,
    PostDraftStatus? status,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (communityDescription != null) {
        updates['communityDescription'] = communityDescription;
      }
      if (scheduledFor != null) {
        updates['scheduledFor'] = Timestamp.fromDate(scheduledFor);
        updates['status'] = PostDraftStatus.scheduled.name;
      }
      if (status != null) {
        updates['status'] = status.name;
      }

      await _draftsCollection(userId).doc(draftId).update(updates);
    } catch (e) {
      debugPrint('Error updating draft: $e');
      rethrow;
    }
  }

  /// Delete a draft
  Future<void> deleteDraft(String userId, String draftId) async {
    try {
      await _draftsCollection(userId).doc(draftId).delete();
    } catch (e) {
      debugPrint('Error deleting draft: $e');
      rethrow;
    }
  }

  /// Mark a draft as published
  Future<void> markAsPublished(String userId, String draftId) async {
    try {
      await _draftsCollection(userId).doc(draftId).update({
        'status': PostDraftStatus.published.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error marking draft as published: $e');
      rethrow;
    }
  }

  /// Get drafts that are ready to be published (scheduled time has passed)
  Future<List<PostDraftModel>> getReadyToPublishDrafts(String userId) async {
    try {
      final snapshot = await _draftsCollection(userId)
          .where('status', isEqualTo: PostDraftStatus.scheduled.name)
          .where('scheduledFor', isLessThanOrEqualTo: Timestamp.now())
          .get();

      return snapshot.docs.map((doc) => PostDraftModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting ready-to-publish drafts: $e');
      return [];
    }
  }

  /// Count unpublished drafts for a user
  Future<int> countUnpublishedDrafts(String userId) async {
    try {
      final snapshot = await _draftsCollection(userId)
          .where('status', whereIn: ['draft', 'scheduled'])
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error counting drafts: $e');
      return 0;
    }
  }
}
