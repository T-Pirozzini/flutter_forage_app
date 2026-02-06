import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/data/models/roadmap_item.dart';
import 'package:flutter_forager_app/data/repositories/base_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';

/// Repository for managing roadmap/changelog items
///
/// Firestore collection: `/Roadmap/{itemId}`
class RoadmapRepository extends BaseRepository<RoadmapItemModel> {
  RoadmapRepository({required FirestoreService firestoreService})
      : super(
          firestoreService: firestoreService,
          collectionPath: 'Roadmap',
        );

  @override
  RoadmapItemModel fromFirestore(DocumentSnapshot doc) {
    return RoadmapItemModel.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(RoadmapItemModel model) {
    return model.toMap();
  }

  /// Stream all roadmap items ordered by date (newest first)
  Stream<List<RoadmapItemModel>> streamAllItems() {
    return firestoreService
        .collection(collectionPath)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Stream items by status
  Stream<List<RoadmapItemModel>> streamByStatus(RoadmapStatus status) {
    return firestoreService
        .collection(collectionPath)
        .where('status', isEqualTo: status.name)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Get completed items only
  Stream<List<RoadmapItemModel>> streamCompletedItems() {
    return streamByStatus(RoadmapStatus.completed);
  }

  /// Get in-progress items only
  Stream<List<RoadmapItemModel>> streamInProgressItems() {
    return streamByStatus(RoadmapStatus.inProgress);
  }

  /// Get planned items only
  Stream<List<RoadmapItemModel>> streamPlannedItems() {
    return streamByStatus(RoadmapStatus.planned);
  }

  /// Add a new roadmap item (admin only)
  Future<String> addItem(RoadmapItemModel item) async {
    return await create(item);
  }

  /// Update a roadmap item (admin only)
  Future<void> updateItem(RoadmapItemModel item) async {
    await update(item.id, item.toMap());
  }

  /// Update just the status of an item
  Future<void> updateStatus(String itemId, RoadmapStatus newStatus) async {
    await update(itemId, {'status': newStatus.name});
  }

  /// Delete a roadmap item (admin only)
  Future<void> deleteItem(String itemId) async {
    await delete(itemId);
  }

  /// Get recent items (last 10)
  Future<List<RoadmapItemModel>> getRecentItems({int limit = 10}) async {
    final snapshot = await firestoreService
        .collection(collectionPath)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }
}
