import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/data/models/app_notification.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';

/// Repository for managing in-app notifications.
///
/// Notifications are stored at: Users/{email}/Notifications/{notificationId}
class NotificationRepository {
  final FirestoreService firestoreService;

  NotificationRepository({required this.firestoreService});

  CollectionReference _collection(String userId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Notifications');
  }

  /// Stream all notifications for a user, newest first.
  Stream<List<AppNotification>> streamNotifications(String userId) {
    return _collection(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream unread notification count.
  Stream<int> streamUnreadCount(String userId) {
    return _collection(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String userId, String notificationId) async {
    await _collection(userId).doc(notificationId).update({'isRead': true});
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead(String userId) async {
    final unread = await _collection(userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = firestoreService.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete a notification.
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _collection(userId).doc(notificationId).delete();
  }

  /// Add a notification (used when saving foreground notifications locally).
  Future<void> addNotification(String userId, AppNotification notification) async {
    await _collection(userId).add(notification.toMap());
  }
}
