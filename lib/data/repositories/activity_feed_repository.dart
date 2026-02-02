import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/data/models/activity_item.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';

/// Repository for managing the activity feed.
///
/// Activity items are stored at: /Users/{userId}/ActivityFeed/{activityId}
/// Activities are pushed (fan-out) to each friend's feed when actions occur.
class ActivityFeedRepository {
  final FirestoreService firestoreService;

  ActivityFeedRepository({required this.firestoreService});

  /// Stream the activity feed for a user
  Stream<List<ActivityItemModel>> streamFeed(String userId, {int limit = 50}) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('ActivityFeed')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityItemModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get activity feed (one-time fetch)
  Future<List<ActivityItemModel>> getFeed(String userId, {int limit = 50}) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('ActivityFeed')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ActivityItemModel.fromFirestore(doc))
        .toList();
  }

  /// Get unread activity count
  Future<int> getUnreadCount(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('ActivityFeed')
        .where('read', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Stream unread count
  Stream<int> streamUnreadCount(String userId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('ActivityFeed')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark a single activity as read
  Future<void> markAsRead(String userId, String activityId) async {
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('ActivityFeed')
        .doc(activityId)
        .update({'read': true});
  }

  /// Mark all activities as read
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('ActivityFeed')
        .where('read', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = firestoreService.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();

    debugPrint('Marked ${snapshot.docs.length} activities as read');
  }

  /// Add an activity to a user's feed
  Future<String> addActivity({
    required String userId,
    required ActivityItemModel activity,
  }) async {
    final docRef = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('ActivityFeed')
        .add(activity.toMap());

    return docRef.id;
  }

  /// Publish activity to all friends (fan-out)
  /// This should typically be done via Cloud Functions for efficiency
  Future<void> publishToFriends({
    required String actorEmail,
    required List<String> friendEmails,
    required ActivityItemModel activity,
  }) async {
    final batch = firestoreService.batch();

    for (final friendEmail in friendEmails) {
      final docRef = firestoreService
          .collection('Users')
          .doc(friendEmail)
          .collection('ActivityFeed')
          .doc();

      batch.set(docRef, activity.toMap());
    }

    await batch.commit();
    debugPrint('Published activity to ${friendEmails.length} friends');
  }

  /// Delete old activities (cleanup)
  Future<void> deleteOldActivities(String userId, {int keepDays = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('ActivityFeed')
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = firestoreService.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    debugPrint('Deleted ${snapshot.docs.length} old activities');
  }

  /// Delete a specific activity
  Future<void> deleteActivity(String userId, String activityId) async {
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('ActivityFeed')
        .doc(activityId)
        .delete();
  }
}
