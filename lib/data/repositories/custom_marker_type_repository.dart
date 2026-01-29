import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/data/repositories/base_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';
import 'package:flutter_forager_app/data/models/custom_marker_type.dart';

/// Repository for managing custom marker types
///
/// Custom marker types are user-defined marker categories with emoji icons.
/// Stored in Firestore at: CustomMarkerTypes/{typeId}
class CustomMarkerTypeRepository extends BaseRepository<CustomMarkerType> {
  CustomMarkerTypeRepository({required super.firestoreService})
      : super(collectionPath: 'CustomMarkerTypes');

  @override
  CustomMarkerType fromFirestore(DocumentSnapshot doc) {
    return CustomMarkerType.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(CustomMarkerType model) {
    return model.toMap();
  }

  /// Stream custom marker types for a specific user
  Stream<List<CustomMarkerType>> streamByUserId(String userId) {
    return streamQueryByField('userId', userId);
  }

  /// Get custom marker types for a specific user
  Future<List<CustomMarkerType>> getByUserId(String userId) {
    return queryByField('userId', userId);
  }

  /// Create a new custom marker type
  Future<String> createType({
    required String name,
    required String emoji,
    required String userId,
  }) async {
    final type = CustomMarkerType(
      id: '', // Will be assigned by Firestore
      name: name,
      emoji: emoji,
      userId: userId,
      createdAt: DateTime.now(),
    );
    return create(type);
  }

  /// Delete a custom marker type by ID
  Future<void> deleteType(String typeId) async {
    await delete(typeId);
  }

  /// Check if user has reached max custom types (limit: 20)
  Future<bool> hasReachedLimit(String userId, {int limit = 20}) async {
    final types = await getByUserId(userId);
    return types.length >= limit;
  }
}
