import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/data/models/direct_message.dart';
import 'package:flutter_forager_app/data/repositories/base_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';

/// Repository for managing direct messages to admin
///
/// Firestore collection: `/DirectMessages/{messageId}`
class DirectMessageRepository extends BaseRepository<DirectMessageModel> {
  DirectMessageRepository({required FirestoreService firestoreService})
      : super(
          firestoreService: firestoreService,
          collectionPath: 'DirectMessages',
        );

  @override
  DirectMessageModel fromFirestore(DocumentSnapshot doc) {
    return DirectMessageModel.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(DirectMessageModel model) {
    return model.toMap();
  }

  /// Send a new message to admin
  Future<String> sendMessage(DirectMessageModel message) async {
    return await create(message);
  }

  /// Stream all messages (for admin view)
  Stream<List<DirectMessageModel>> streamAllMessages() {
    return firestoreService
        .collection(collectionPath)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Stream unread messages count (for admin badge)
  Stream<int> streamUnreadCount() {
    return firestoreService
        .collection(collectionPath)
        .where('status', isEqualTo: MessageStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream messages by user (for "My Messages" section)
  Stream<List<DirectMessageModel>> streamUserMessages(String userEmail) {
    return firestoreService
        .collection(collectionPath)
        .where('userEmail', isEqualTo: userEmail)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    await update(messageId, {
      'status': MessageStatus.read.name,
    });
  }

  /// Mark all messages as read
  Future<void> markAllAsRead() async {
    final snapshot = await firestoreService
        .collection(collectionPath)
        .where('status', isEqualTo: MessageStatus.pending.name)
        .get();

    final batch = firestoreService.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'status': MessageStatus.read.name});
    }
    await batch.commit();
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await delete(messageId);
  }

  /// Get messages by category (for filtering)
  Stream<List<DirectMessageModel>> streamByCategory(MessageCategory category) {
    return firestoreService
        .collection(collectionPath)
        .where('category', isEqualTo: category.name)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }
}
