import 'package:cloud_firestore/cloud_firestore.dart';

/// Wrapper around FirebaseFirestore to enable easy testing and mocking
///
/// This service provides a single point of access to Firestore,
/// making it easier to add caching, offline support, and logging later.
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get a collection reference
  CollectionReference collection(String path) {
    return _firestore.collection(path);
  }

  /// Get a collection group reference (queries across all subcollections with the same name)
  Query collectionGroup(String collectionId) {
    return _firestore.collectionGroup(collectionId);
  }

  /// Get a document reference
  DocumentReference doc(String path) {
    return _firestore.doc(path);
  }

  /// Get Firestore instance directly (for advanced queries)
  FirebaseFirestore get instance => _firestore;

  /// Run a batch write
  WriteBatch batch() {
    return _firestore.batch();
  }

  /// Run a transaction
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    return _firestore.runTransaction(transactionHandler, timeout: timeout);
  }
}
