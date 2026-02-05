import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/data/models/friend.dart';
import 'package:flutter_forager_app/data/models/friend_request.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';

/// Repository for managing friend relationships and friend requests.
///
/// Uses Firestore subcollections for scalability:
/// - /Users/{userId}/Friends/{friendEmail} - Friend relationships
/// - /Users/{userId}/FriendRequests/{requestId} - Friend requests
///
/// Also maintains a FriendshipIndex collection for efficient bidirectional queries.
class FriendRepository {
  final FirestoreService firestoreService;

  FriendRepository({required this.firestoreService});

  // ============ FRIEND MANAGEMENT ============

  /// Stream all friends for a user
  Stream<List<FriendModel>> streamFriends(String userId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Friends')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FriendModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get all friends for a user (one-time fetch)
  Future<List<FriendModel>> getFriends(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Friends')
        .orderBy('addedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => FriendModel.fromFirestore(doc)).toList();
  }

  /// Check if two users are friends
  Future<bool> areFriends(String userId, String friendEmail) async {
    final doc = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Friends')
        .doc(friendEmail)
        .get();

    return doc.exists;
  }

  /// Add a friend (bidirectional - adds to both users' subcollections)
  ///
  /// Uses batch write for atomicity.
  Future<void> addFriend({
    required String userId,
    required String userDisplayName,
    required String userPhotoUrl,
    required String friendEmail,
    required String friendDisplayName,
    required String friendPhotoUrl,
  }) async {
    final batch = firestoreService.batch();
    final now = DateTime.now();

    // Add friend to user's subcollection
    final userFriendRef = firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Friends')
        .doc(friendEmail);

    batch.set(
        userFriendRef,
        FriendModel(
          friendEmail: friendEmail,
          displayName: friendDisplayName,
          photoUrl: friendPhotoUrl.isNotEmpty ? friendPhotoUrl : null,
          addedAt: now,
        ).toMap());

    // Add user to friend's subcollection (reverse)
    final friendUserRef = firestoreService
        .collection('Users')
        .doc(friendEmail)
        .collection('Friends')
        .doc(userId);

    batch.set(
        friendUserRef,
        FriendModel(
          friendEmail: userId,
          displayName: userDisplayName,
          photoUrl: userPhotoUrl.isNotEmpty ? userPhotoUrl : null,
          addedAt: now,
        ).toMap());

    // Create friendship index for efficient queries
    final indexId = _createFriendshipIndexId(userId, friendEmail);
    final indexRef =
        firestoreService.collection('FriendshipIndex').doc(indexId);

    batch.set(indexRef, {
      'users': [userId, friendEmail]..sort(),
      'createdAt': Timestamp.fromDate(now),
      'status': 'active',
    });

    await batch.commit();
    debugPrint('Friend added: $userId <-> $friendEmail');
  }

  /// Remove a friend (bidirectional)
  Future<void> removeFriend(String userId, String friendEmail) async {
    final batch = firestoreService.batch();

    // Remove from user's subcollection
    final userFriendRef = firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Friends')
        .doc(friendEmail);
    batch.delete(userFriendRef);

    // Remove from friend's subcollection
    final friendUserRef = firestoreService
        .collection('Users')
        .doc(friendEmail)
        .collection('Friends')
        .doc(userId);
    batch.delete(friendUserRef);

    // Remove friendship index
    final indexId = _createFriendshipIndexId(userId, friendEmail);
    final indexRef =
        firestoreService.collection('FriendshipIndex').doc(indexId);
    batch.delete(indexRef);

    await batch.commit();
    debugPrint('Friend removed: $userId <-> $friendEmail');
  }

  /// Update friend's close friend status
  Future<void> setCloseFriend(
      String userId, String friendEmail, bool isCloseFriend) async {
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Friends')
        .doc(friendEmail)
        .update({'closeFriend': isCloseFriend});
  }

  /// Update friend's emergency contact status
  ///
  /// Emergency contacts receive safety notifications when the user
  /// plans to forage with someone new.
  Future<void> setEmergencyContact(
      String userId, String friendEmail, bool isEmergencyContact) async {
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Friends')
        .doc(friendEmail)
        .update({'isEmergencyContact': isEmergencyContact});
  }

  /// Get emergency contacts only
  Stream<List<FriendModel>> streamEmergencyContacts(String userId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Friends')
        .where('isEmergencyContact', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FriendModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get emergency contacts (one-time fetch)
  Future<List<FriendModel>> getEmergencyContacts(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Friends')
        .where('isEmergencyContact', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => FriendModel.fromFirestore(doc)).toList();
  }

  /// Get close friends only
  Stream<List<FriendModel>> streamCloseFriends(String userId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Friends')
        .where('closeFriend', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FriendModel.fromFirestore(doc))
          .toList();
    });
  }

  // ============ FRIEND REQUESTS ============

  /// Stream incoming friend requests for a user
  Stream<List<FriendRequestModel>> streamIncomingRequests(String userId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('FriendRequests')
        .where('toEmail', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FriendRequestModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream outgoing friend requests for a user
  Stream<List<FriendRequestModel>> streamOutgoingRequests(String userId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('FriendRequests')
        .where('fromEmail', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FriendRequestModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Send a friend request
  ///
  /// Creates a request in the recipient's FriendRequests subcollection.
  /// Optionally includes a short intro message (150 char max).
  Future<void> sendRequest({
    required String fromEmail,
    required String fromDisplayName,
    String? fromPhotoUrl,
    required String toEmail,
    String toDisplayName = '',
    String? message,
  }) async {
    // Check if already friends
    if (await areFriends(fromEmail, toEmail)) {
      throw Exception('Already friends');
    }

    // Check for existing pending request
    final existingRequests = await firestoreService
        .collection('Users')
        .doc(toEmail)
        .collection('FriendRequests')
        .where('fromEmail', isEqualTo: fromEmail)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingRequests.docs.isNotEmpty) {
      throw Exception('Friend request already pending');
    }

    // Validate message length
    if (message != null && message.length > 150) {
      throw Exception('Message must be 150 characters or less');
    }

    final request = FriendRequestModel(
      id: '',
      fromEmail: fromEmail,
      fromDisplayName: fromDisplayName,
      fromPhotoUrl: fromPhotoUrl,
      toEmail: toEmail,
      toDisplayName: toDisplayName,
      message: message,
      status: FriendRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    // Add to recipient's FriendRequests subcollection
    await firestoreService
        .collection('Users')
        .doc(toEmail)
        .collection('FriendRequests')
        .add(request.toMap());

    debugPrint('Friend request sent: $fromEmail -> $toEmail');
  }

  /// Accept a friend request
  ///
  /// Updates request status and creates bidirectional friend relationship.
  Future<void> acceptRequest({
    required String userId,
    required String requestId,
    required String userDisplayName,
    String? userPhotoUrl,
  }) async {
    // Get the request
    final requestDoc = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('FriendRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) {
      throw Exception('Friend request not found');
    }

    final request = FriendRequestModel.fromFirestore(requestDoc);

    // Update request status
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('FriendRequests')
        .doc(requestId)
        .update({
      'status': FriendRequestStatus.accepted.name,
      'respondedAt': Timestamp.now(),
    });

    // Add friend relationship
    await addFriend(
      userId: userId,
      userDisplayName: userDisplayName,
      userPhotoUrl: userPhotoUrl ?? '',
      friendEmail: request.fromEmail,
      friendDisplayName: request.fromDisplayName,
      friendPhotoUrl: request.fromPhotoUrl ?? '',
    );

    debugPrint('Friend request accepted: ${request.fromEmail} -> $userId');
  }

  /// Decline a friend request
  Future<void> declineRequest(String userId, String requestId) async {
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('FriendRequests')
        .doc(requestId)
        .update({
      'status': FriendRequestStatus.declined.name,
      'respondedAt': Timestamp.now(),
    });

    debugPrint('Friend request declined: $requestId');
  }

  /// Cancel a sent friend request
  Future<void> cancelRequest(String fromEmail, String toEmail) async {
    // Find and delete the request from recipient's subcollection
    final requests = await firestoreService
        .collection('Users')
        .doc(toEmail)
        .collection('FriendRequests')
        .where('fromEmail', isEqualTo: fromEmail)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final doc in requests.docs) {
      await doc.reference.delete();
    }

    debugPrint('Friend request cancelled: $fromEmail -> $toEmail');
  }

  /// Check if there's a pending request between two users
  Future<bool> hasPendingRequest(String fromEmail, String toEmail) async {
    final requests = await firestoreService
        .collection('Users')
        .doc(toEmail)
        .collection('FriendRequests')
        .where('fromEmail', isEqualTo: fromEmail)
        .where('status', isEqualTo: 'pending')
        .get();

    return requests.docs.isNotEmpty;
  }

  /// Get count of pending incoming requests
  Future<int> getPendingRequestCount(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('FriendRequests')
        .where('toEmail', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ============ HELPERS ============

  /// Create a consistent friendship index ID from two user emails
  String _createFriendshipIndexId(String email1, String email2) {
    final sorted = [email1, email2]..sort();
    return '${sorted[0]}_${sorted[1]}'
        .replaceAll('.', '_')
        .replaceAll('@', '_');
  }

  /// Get friend count for a user
  Future<int> getFriendCount(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Friends')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Search friends by display name
  Stream<List<FriendModel>> searchFriends(String userId, String query) {
    if (query.isEmpty) return streamFriends(userId);

    final queryLower = query.toLowerCase();

    return streamFriends(userId).map((friends) {
      return friends
          .where((friend) =>
              friend.displayName.toLowerCase().contains(queryLower) ||
              friend.friendEmail.toLowerCase().contains(queryLower))
          .toList();
    });
  }
}
