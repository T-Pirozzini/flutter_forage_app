import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/data/models/forage_request.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';

/// Repository for managing "Let's Forage Together" requests.
///
/// Uses Firestore collection at: /ForageRequests/{requestId}
///
/// Flow:
/// 1. User A discovers User B via "Nearby Foragers"
/// 2. User A sends a forage request with short intro message
/// 3. User B accepts or declines (with optional response)
/// 4. If accepted, both users exchange contact info for off-platform communication
class ForageRequestRepository {
  final FirestoreService firestoreService;
  static const String _collectionPath = 'ForageRequests';

  ForageRequestRepository({required this.firestoreService});

  // ============ SENDING REQUESTS ============

  /// Send a forage request to another user
  ///
  /// [fromEmail] - Sender's email
  /// [fromUsername] - Sender's display name
  /// [toEmail] - Recipient's email
  /// [toUsername] - Recipient's display name
  /// [message] - Short intro message (max 150 chars)
  Future<String> sendRequest({
    required String fromEmail,
    required String fromUsername,
    required String toEmail,
    required String toUsername,
    required String message,
  }) async {
    // Validate message length
    if (message.length > 150) {
      throw Exception('Message must be 150 characters or less');
    }

    // Check for existing pending request
    final existingRequest = await _getExistingPendingRequest(fromEmail, toEmail);
    if (existingRequest != null) {
      throw Exception('You already have a pending request to this user');
    }

    // Check for reverse pending request
    final reverseRequest = await _getExistingPendingRequest(toEmail, fromEmail);
    if (reverseRequest != null) {
      throw Exception('This user has already sent you a request');
    }

    final request = ForageRequest(
      id: '',
      fromEmail: fromEmail,
      fromUsername: fromUsername,
      toEmail: toEmail,
      toUsername: toUsername,
      message: message,
      status: ForageRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    final docRef = await firestoreService
        .collection(_collectionPath)
        .add(request.toMap());

    debugPrint('Forage request sent: $fromEmail -> $toEmail');
    return docRef.id;
  }

  // ============ RESPONDING TO REQUESTS ============

  /// Accept a forage request
  ///
  /// Optionally includes a response message from the recipient.
  Future<void> acceptRequest({
    required String requestId,
    String? responseMessage,
  }) async {
    final updateData = <String, dynamic>{
      'status': ForageRequestStatus.accepted.name,
      'respondedAt': Timestamp.now(),
    };

    if (responseMessage != null && responseMessage.isNotEmpty) {
      if (responseMessage.length > 150) {
        throw Exception('Response must be 150 characters or less');
      }
      updateData['responseMessage'] = responseMessage;
    }

    await firestoreService
        .collection(_collectionPath)
        .doc(requestId)
        .update(updateData);

    debugPrint('Forage request accepted: $requestId');
  }

  /// Decline a forage request
  ///
  /// Optionally includes a response message explaining the decline.
  Future<void> declineRequest({
    required String requestId,
    String? responseMessage,
  }) async {
    final updateData = <String, dynamic>{
      'status': ForageRequestStatus.declined.name,
      'respondedAt': Timestamp.now(),
    };

    if (responseMessage != null && responseMessage.isNotEmpty) {
      if (responseMessage.length > 150) {
        throw Exception('Response must be 150 characters or less');
      }
      updateData['responseMessage'] = responseMessage;
    }

    await firestoreService
        .collection(_collectionPath)
        .doc(requestId)
        .update(updateData);

    debugPrint('Forage request declined: $requestId');
  }

  // ============ CONTACT EXCHANGE ============

  /// Update sender's contact info after mutual acceptance
  Future<void> updateSenderContact({
    required String requestId,
    required String contactMethod,
    required String contactInfo,
  }) async {
    await firestoreService
        .collection(_collectionPath)
        .doc(requestId)
        .update({
      'fromContactMethod': contactMethod,
      'fromContactInfo': contactInfo,
    });

    debugPrint('Sender contact updated for request: $requestId');
  }

  /// Update recipient's contact info after mutual acceptance
  Future<void> updateRecipientContact({
    required String requestId,
    required String contactMethod,
    required String contactInfo,
  }) async {
    await firestoreService
        .collection(_collectionPath)
        .doc(requestId)
        .update({
      'toContactMethod': contactMethod,
      'toContactInfo': contactInfo,
    });

    debugPrint('Recipient contact updated for request: $requestId');
  }

  // ============ QUERYING REQUESTS ============

  /// Stream incoming forage requests (where user is recipient)
  Stream<List<ForageRequest>> streamIncomingRequests(String userEmail) {
    return firestoreService
        .collection(_collectionPath)
        .where('toEmail', isEqualTo: userEmail)
        .where('status', isEqualTo: ForageRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ForageRequest.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream outgoing forage requests (where user is sender)
  Stream<List<ForageRequest>> streamOutgoingRequests(String userEmail) {
    return firestoreService
        .collection(_collectionPath)
        .where('fromEmail', isEqualTo: userEmail)
        .where('status', isEqualTo: ForageRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ForageRequest.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream accepted requests where contact exchange is complete
  ///
  /// These are successful connections where both users have shared contact info.
  Stream<List<ForageRequest>> streamCompletedConnections(String userEmail) {
    return firestoreService
        .collection(_collectionPath)
        .where('status', isEqualTo: ForageRequestStatus.accepted.name)
        .orderBy('respondedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ForageRequest.fromFirestore(doc))
          .where((request) => request.involvesUser(userEmail))
          .where((request) => request.hasContactExchange)
          .toList();
    });
  }

  /// Stream accepted requests pending contact exchange
  ///
  /// These are accepted requests where contact info hasn't been shared yet.
  Stream<List<ForageRequest>> streamPendingContactExchange(String userEmail) {
    return firestoreService
        .collection(_collectionPath)
        .where('status', isEqualTo: ForageRequestStatus.accepted.name)
        .orderBy('respondedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ForageRequest.fromFirestore(doc))
          .where((request) => request.involvesUser(userEmail))
          .where((request) => !request.hasContactExchange)
          .toList();
    });
  }

  /// Get a single forage request by ID
  Future<ForageRequest?> getRequest(String requestId) async {
    final doc = await firestoreService
        .collection(_collectionPath)
        .doc(requestId)
        .get();

    if (!doc.exists) return null;
    return ForageRequest.fromFirestore(doc);
  }

  /// Stream a single forage request by ID
  Stream<ForageRequest?> streamRequest(String requestId) {
    return firestoreService
        .collection(_collectionPath)
        .doc(requestId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return ForageRequest.fromFirestore(doc);
    });
  }

  /// Get all requests involving a user (both sent and received)
  Future<List<ForageRequest>> getAllRequestsForUser(String userEmail) async {
    // Query for sent requests
    final sentSnapshot = await firestoreService
        .collection(_collectionPath)
        .where('fromEmail', isEqualTo: userEmail)
        .get();

    // Query for received requests
    final receivedSnapshot = await firestoreService
        .collection(_collectionPath)
        .where('toEmail', isEqualTo: userEmail)
        .get();

    final allRequests = <ForageRequest>[];

    for (final doc in sentSnapshot.docs) {
      allRequests.add(ForageRequest.fromFirestore(doc));
    }

    for (final doc in receivedSnapshot.docs) {
      allRequests.add(ForageRequest.fromFirestore(doc));
    }

    // Sort by createdAt descending
    allRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return allRequests;
  }

  /// Get count of pending incoming requests
  Future<int> getPendingIncomingCount(String userEmail) async {
    final snapshot = await firestoreService
        .collection(_collectionPath)
        .where('toEmail', isEqualTo: userEmail)
        .where('status', isEqualTo: ForageRequestStatus.pending.name)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ============ CANCELLATION ============

  /// Cancel a sent forage request (only sender can cancel)
  Future<void> cancelRequest(String requestId, String senderEmail) async {
    final request = await getRequest(requestId);

    if (request == null) {
      throw Exception('Request not found');
    }

    if (request.fromEmail != senderEmail) {
      throw Exception('Only the sender can cancel a request');
    }

    if (request.status != ForageRequestStatus.pending) {
      throw Exception('Can only cancel pending requests');
    }

    await firestoreService
        .collection(_collectionPath)
        .doc(requestId)
        .delete();

    debugPrint('Forage request cancelled: $requestId');
  }

  // ============ HELPERS ============

  /// Check for existing pending request between two users
  Future<ForageRequest?> _getExistingPendingRequest(
    String fromEmail,
    String toEmail,
  ) async {
    final snapshot = await firestoreService
        .collection(_collectionPath)
        .where('fromEmail', isEqualTo: fromEmail)
        .where('toEmail', isEqualTo: toEmail)
        .where('status', isEqualTo: ForageRequestStatus.pending.name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ForageRequest.fromFirestore(snapshot.docs.first);
  }

  /// Check if user has any pending request to another user
  Future<bool> hasPendingRequestTo(String fromEmail, String toEmail) async {
    final request = await _getExistingPendingRequest(fromEmail, toEmail);
    return request != null;
  }

  /// Check if user has any pending request from another user
  Future<bool> hasPendingRequestFrom(String fromEmail, String toEmail) async {
    final request = await _getExistingPendingRequest(fromEmail, toEmail);
    return request != null;
  }

  /// Expire old pending requests (call periodically via Cloud Function)
  ///
  /// Marks requests older than [daysOld] as expired.
  Future<int> expireOldRequests({int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    final snapshot = await firestoreService
        .collection(_collectionPath)
        .where('status', isEqualTo: ForageRequestStatus.pending.name)
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();

    final batch = firestoreService.batch();
    int count = 0;

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': ForageRequestStatus.expired.name,
      });
      count++;
    }

    if (count > 0) {
      await batch.commit();
      debugPrint('Expired $count old forage requests');
    }

    return count;
  }
}
