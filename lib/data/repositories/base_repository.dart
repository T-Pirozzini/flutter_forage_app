import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';

/// Base repository class with common CRUD operations
///
/// This abstract class provides reusable patterns for all repositories:
/// - Centralized Firestore access through FirestoreService
/// - Type-safe document conversion
/// - Error handling patterns
/// - Consistent API surface
///
/// Type parameter [T] is the model type (e.g., UserModel, MarkerModel)
abstract class BaseRepository<T> {
  final FirestoreService firestoreService;
  final String collectionPath;

  BaseRepository({
    required this.firestoreService,
    required this.collectionPath,
  });

  /// Convert Firestore DocumentSnapshot to model
  /// Must be implemented by subclasses
  T fromFirestore(DocumentSnapshot doc);

  /// Convert model to Firestore map
  /// Must be implemented by subclasses
  Map<String, dynamic> toFirestore(T model);

  /// Get a document by ID
  Future<T?> getById(String id) async {
    try {
      final doc = await firestoreService
          .collection(collectionPath)
          .doc(id)
          .get();

      if (!doc.exists) return null;
      return fromFirestore(doc);
    } catch (e) {
      // TODO: Add proper error logging
      rethrow;
    }
  }

  /// Stream a document by ID (real-time updates)
  Stream<T?> streamById(String id) {
    return firestoreService
        .collection(collectionPath)
        .doc(id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return fromFirestore(doc);
    });
  }

  /// Get all documents in collection
  Future<List<T>> getAll() async {
    try {
      final snapshot = await firestoreService
          .collection(collectionPath)
          .get();

      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      // TODO: Add proper error logging
      rethrow;
    }
  }

  /// Stream all documents (real-time updates)
  Stream<List<T>> streamAll() {
    return firestoreService
        .collection(collectionPath)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Create a new document
  Future<String> create(T model, {String? id}) async {
    try {
      final data = toFirestore(model);

      if (id != null) {
        // Use provided ID
        await firestoreService
            .collection(collectionPath)
            .doc(id)
            .set(data);
        return id;
      } else {
        // Auto-generate ID
        final docRef = await firestoreService
            .collection(collectionPath)
            .add(data);
        return docRef.id;
      }
    } catch (e) {
      // TODO: Add proper error logging
      rethrow;
    }
  }

  /// Update an existing document
  Future<void> update(String id, Map<String, dynamic> updates) async {
    try {
      await firestoreService
          .collection(collectionPath)
          .doc(id)
          .update(updates);
    } catch (e) {
      // TODO: Add proper error logging
      rethrow;
    }
  }

  /// Delete a document
  Future<void> delete(String id) async {
    try {
      await firestoreService
          .collection(collectionPath)
          .doc(id)
          .delete();
    } catch (e) {
      // TODO: Add proper error logging
      rethrow;
    }
  }

  /// Set (overwrite) a document
  Future<void> set(String id, T model) async {
    try {
      final data = toFirestore(model);
      await firestoreService
          .collection(collectionPath)
          .doc(id)
          .set(data);
    } catch (e) {
      // TODO: Add proper error logging
      rethrow;
    }
  }

  /// Query helper: get documents matching a field value
  Future<List<T>> queryByField(String field, dynamic value) async {
    try {
      final snapshot = await firestoreService
          .collection(collectionPath)
          .where(field, isEqualTo: value)
          .get();

      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      // TODO: Add proper error logging
      rethrow;
    }
  }

  /// Query helper: stream documents matching a field value
  Stream<List<T>> streamQueryByField(String field, dynamic value) {
    return firestoreService
        .collection(collectionPath)
        .where(field, isEqualTo: value)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }
}
