import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/data/models/emergency_notification.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';

/// Repository for managing emergency notifications.
///
/// Stored at: /Users/{userId}/EmergencyNotifications/{notificationId}
///
/// Used to notify designated emergency contacts when a user
/// plans to forage with someone, including date, time, and location.
class EmergencyNotificationRepository {
  final FirestoreService firestoreService;

  EmergencyNotificationRepository({required this.firestoreService});

  /// Get the notifications collection for a user
  CollectionReference _getCollection(String userId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('EmergencyNotifications');
  }

  // ============ CREATE ============

  /// Create a new emergency notification
  ///
  /// Notifies all designated emergency contacts about the planned forage.
  Future<String> createNotification({
    required String userId,
    required String userEmail,
    required String username,
    required String partnerUsername,
    required DateTime plannedDateTime,
    required String generalLocation,
    required List<String> emergencyContactEmails,
    String? notes,
  }) async {
    final notification = EmergencyNotification(
      id: '',
      userId: userId,
      userEmail: userEmail,
      username: username,
      partnerUsername: partnerUsername,
      plannedDateTime: plannedDateTime,
      generalLocation: generalLocation,
      notifiedEmails: emergencyContactEmails,
      createdAt: DateTime.now(),
      notes: notes,
    );

    final docRef = await _getCollection(userId).add(notification.toMap());

    debugPrint('Emergency notification created: ${docRef.id}');
    debugPrint('Notified contacts: $emergencyContactEmails');

    // TODO: Integrate with push notifications or email service
    // to actually send notifications to emergency contacts
    // For now, this creates the record in Firestore

    return docRef.id;
  }

  // ============ READ ============

  /// Stream active notifications for a user
  Stream<List<EmergencyNotification>> streamActiveNotifications(String userId) {
    return _getCollection(userId)
        .where('status', isEqualTo: EmergencyNotificationStatus.active.name)
        .orderBy('plannedDateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EmergencyNotification.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream all notifications for a user
  Stream<List<EmergencyNotification>> streamAllNotifications(String userId) {
    return _getCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EmergencyNotification.fromFirestore(doc))
          .toList();
    });
  }

  /// Get a single notification by ID
  Future<EmergencyNotification?> getNotification(
    String userId,
    String notificationId,
  ) async {
    final doc = await _getCollection(userId).doc(notificationId).get();
    if (!doc.exists) return null;
    return EmergencyNotification.fromFirestore(doc);
  }

  /// Get count of active notifications
  Future<int> getActiveNotificationCount(String userId) async {
    final snapshot = await _getCollection(userId)
        .where('status', isEqualTo: EmergencyNotificationStatus.active.name)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ============ UPDATE ============

  /// Mark notification as completed (user returned safely)
  Future<void> markAsCompleted(String userId, String notificationId) async {
    await _getCollection(userId).doc(notificationId).update({
      'status': EmergencyNotificationStatus.completed.name,
      'completedAt': Timestamp.now(),
    });

    debugPrint('Emergency notification marked as completed: $notificationId');
  }

  /// Cancel a notification
  Future<void> cancelNotification(String userId, String notificationId) async {
    await _getCollection(userId).doc(notificationId).update({
      'status': EmergencyNotificationStatus.cancelled.name,
    });

    debugPrint('Emergency notification cancelled: $notificationId');
  }

  /// Update notification details
  Future<void> updateNotification({
    required String userId,
    required String notificationId,
    DateTime? plannedDateTime,
    String? generalLocation,
    String? notes,
  }) async {
    final updates = <String, dynamic>{};

    if (plannedDateTime != null) {
      updates['plannedDateTime'] = Timestamp.fromDate(plannedDateTime);
    }
    if (generalLocation != null) {
      updates['generalLocation'] = generalLocation;
    }
    if (notes != null) {
      updates['notes'] = notes;
    }

    if (updates.isNotEmpty) {
      await _getCollection(userId).doc(notificationId).update(updates);
    }
  }

  // ============ DELETE ============

  /// Delete a notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _getCollection(userId).doc(notificationId).delete();
    debugPrint('Emergency notification deleted: $notificationId');
  }

  // ============ EMERGENCY CONTACTS HELPER ============

  /// Stream notifications where current user was notified as emergency contact
  ///
  /// This allows users to see when their friends have planned forages.
  Stream<List<EmergencyNotification>> streamNotificationsAsEmergencyContact(
    String userEmail,
  ) {
    // This requires a collection group query across all users' EmergencyNotifications
    // Note: Requires Firestore composite index
    return firestoreService
        .collectionGroup('EmergencyNotifications')
        .where('notifiedEmails', arrayContains: userEmail)
        .where('status', isEqualTo: EmergencyNotificationStatus.active.name)
        .orderBy('plannedDateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EmergencyNotification.fromFirestore(doc))
          .toList();
    });
  }
}
