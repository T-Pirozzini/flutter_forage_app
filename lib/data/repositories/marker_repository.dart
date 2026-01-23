import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/core/constants/firestore_collections.dart';
import 'package:flutter_forager_app/data/repositories/base_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';
import 'package:flutter_forager_app/data/models/marker.dart';

/// Repository for managing Marker data
///
/// This repository handles all CRUD operations for markers in the NEW root collection.
/// After migration, all markers will be stored at: Markers/{markerId}
///
/// Key features:
/// - Query markers by user
/// - Query markers by type
/// - Query markers by location (geohash/bounds)
/// - Real-time marker streams
class MarkerRepository extends BaseRepository<MarkerModel> {
  MarkerRepository({required super.firestoreService})
      : super(collectionPath: FirestoreCollections.markers);

  @override
  MarkerModel fromFirestore(DocumentSnapshot doc) {
    return MarkerModel.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(MarkerModel model) {
    return model.toMap();
  }

  // CUSTOM QUERIES

  /// Get all markers owned by a specific user
  Future<List<MarkerModel>> getByUserId(String userId) async {
    return queryByField(FirestoreFields.markerOwner, userId);
  }

  /// Stream markers owned by a specific user (real-time)
  Stream<List<MarkerModel>> streamByUserId(String userId) {
    return streamQueryByField(FirestoreFields.markerOwner, userId);
  }

  /// Get markers by type (e.g., "Berries", "Mushrooms")
  Future<List<MarkerModel>> getByType(String type) async {
    return queryByField(FirestoreFields.type, type);
  }

  /// Stream markers by type (real-time)
  Stream<List<MarkerModel>> streamByType(String type) {
    return streamQueryByField(FirestoreFields.type, type);
  }

  /// Get all public markers (for community feed)
  /// In the future, this should exclude private markers
  Future<List<MarkerModel>> getPublicMarkers() async {
    try {
      final snapshot = await firestoreService
          .collection(collectionPath)
          .orderBy(FirestoreFields.timestamp, descending: true)
          .get();

      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream all public markers (real-time)
  /// [limit] controls max markers loaded (default 100 for performance)
  Stream<List<MarkerModel>> streamPublicMarkers({int limit = 100}) {
    return firestoreService
        .collection(collectionPath)
        .orderBy(FirestoreFields.timestamp, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Add a comment to a marker
  Future<void> addComment({
    required String markerId,
    required String userId,
    required String userEmail,
    required String text,
  }) async {
    final comment = MarkerComment(
      userId: userId,
      userEmail: userEmail,
      text: text,
      timestamp: DateTime.now(),
    );

    await firestoreService
        .collection(collectionPath)
        .doc(markerId)
        .update({
      'comments': FieldValue.arrayUnion([comment.toMap()]),
    });
  }

  /// Update marker status
  Future<void> updateStatus({
    required String markerId,
    required String newStatus,
    required String userId,
    required String userEmail,
    String? username,
    String? notes,
  }) async {
    final statusUpdate = MarkerStatusUpdate(
      status: newStatus,
      userId: userId,
      userEmail: userEmail,
      username: username,
      timestamp: DateTime.now(),
      notes: notes,
    );

    await firestoreService
        .collection(collectionPath)
        .doc(markerId)
        .update({
      'currentStatus': newStatus,
      'statusHistory': FieldValue.arrayUnion([statusUpdate.toMap()]),
    });
  }

  /// Query markers within a geographic bounding box
  /// This is a basic implementation - for production, use geohashing
  Future<List<MarkerModel>> getMarkersInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    try {
      // Note: This requires composite indexes in Firestore
      // For now, we'll fetch all and filter in-memory
      final allMarkers = await getPublicMarkers();

      return allMarkers.where((marker) {
        return marker.latitude >= minLat &&
            marker.latitude <= maxLat &&
            marker.longitude >= minLng &&
            marker.longitude <= maxLng;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's bookmarked markers
  /// This requires the marker IDs from user's savedLocations
  Future<List<MarkerModel>> getBookmarkedMarkers(List<String> markerIds) async {
    if (markerIds.isEmpty) return [];

    try {
      // Firestore 'in' queries are limited to 10 items
      // For larger lists, we need to batch the queries
      const batchSize = 10;
      final List<MarkerModel> allMarkers = [];

      for (var i = 0; i < markerIds.length; i += batchSize) {
        final batch = markerIds.skip(i).take(batchSize).toList();
        final snapshot = await firestoreService
            .collection(collectionPath)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        allMarkers.addAll(
          snapshot.docs.map((doc) => fromFirestore(doc)).toList(),
        );
      }

      return allMarkers;
    } catch (e) {
      rethrow;
    }
  }
}
