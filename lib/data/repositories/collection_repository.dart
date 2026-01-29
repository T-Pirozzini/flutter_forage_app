import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/data/models/collection_subscription.dart';
import 'package:flutter_forager_app/data/models/location_collection.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';

/// Repository for managing location collections and subscriptions.
///
/// Collections are stored at: /Users/{userId}/Collections/{collectionId}
/// Subscriptions are stored at: /Users/{userId}/Subscriptions/{subscriptionId}
class CollectionRepository {
  final FirestoreService firestoreService;

  CollectionRepository({required this.firestoreService});

  // ============== OWN COLLECTIONS ==============

  /// Stream all collections owned by a user
  Stream<List<LocationCollectionModel>> streamMyCollections(String userId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Collections')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LocationCollectionModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get all collections owned by a user (one-time fetch)
  Future<List<LocationCollectionModel>> getMyCollections(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Collections')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => LocationCollectionModel.fromFirestore(doc))
        .toList();
  }

  /// Get a single collection by ID
  Future<LocationCollectionModel?> getCollection(
      String userId, String collectionId) async {
    final doc = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Collections')
        .doc(collectionId)
        .get();

    if (!doc.exists) return null;
    return LocationCollectionModel.fromFirestore(doc);
  }

  /// Create a new collection
  Future<String> createCollection({
    required String userId,
    required String userDisplayName,
    required String name,
    String? description,
    bool isPublic = false,
    List<String> markerIds = const [],
    String? coverImageUrl,
  }) async {
    final collection = LocationCollectionModel(
      id: '',
      name: name,
      description: description,
      isPublic: isPublic,
      createdAt: DateTime.now(),
      markerIds: markerIds,
      ownerEmail: userId,
      ownerDisplayName: userDisplayName,
      coverImageUrl: coverImageUrl,
    );

    final docRef = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Collections')
        .add(collection.toMap());

    debugPrint('Collection created: ${docRef.id}');
    return docRef.id;
  }

  /// Update a collection
  Future<void> updateCollection({
    required String userId,
    required String collectionId,
    String? name,
    String? description,
    bool? isPublic,
    List<String>? markerIds,
    String? coverImageUrl,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (isPublic != null) updates['isPublic'] = isPublic;
    if (markerIds != null) updates['markerIds'] = markerIds;
    if (coverImageUrl != null) updates['coverImageUrl'] = coverImageUrl;

    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Collections')
        .doc(collectionId)
        .update(updates);

    debugPrint('Collection updated: $collectionId');
  }

  /// Delete a collection
  Future<void> deleteCollection(String userId, String collectionId) async {
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Collections')
        .doc(collectionId)
        .delete();

    debugPrint('Collection deleted: $collectionId');
  }

  /// Add a marker to a collection
  Future<void> addMarkerToCollection({
    required String userId,
    required String collectionId,
    required String markerId,
  }) async {
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Collections')
        .doc(collectionId)
        .update({
      'markerIds': FieldValue.arrayUnion([markerId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove a marker from a collection
  Future<void> removeMarkerFromCollection({
    required String userId,
    required String collectionId,
    required String markerId,
  }) async {
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Collections')
        .doc(collectionId)
        .update({
      'markerIds': FieldValue.arrayRemove([markerId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============== PUBLIC COLLECTIONS (DISCOVERY) ==============

  /// Stream public collections from a specific user (for friend discovery)
  Stream<List<LocationCollectionModel>> streamPublicCollections(
      String ownerEmail) {
    return firestoreService
        .collection('Users')
        .doc(ownerEmail)
        .collection('Collections')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LocationCollectionModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get public collections from a specific user
  Future<List<LocationCollectionModel>> getPublicCollections(
      String ownerEmail) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(ownerEmail)
        .collection('Collections')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => LocationCollectionModel.fromFirestore(doc))
        .toList();
  }

  // ============== SUBSCRIPTIONS ==============

  /// Stream user's subscriptions to other collections
  Stream<List<CollectionSubscriptionModel>> streamSubscriptions(String userId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Subscriptions')
        .orderBy('subscribedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CollectionSubscriptionModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get user's subscriptions (one-time fetch)
  Future<List<CollectionSubscriptionModel>> getSubscriptions(
      String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Subscriptions')
        .orderBy('subscribedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CollectionSubscriptionModel.fromFirestore(doc))
        .toList();
  }

  /// Check if user is subscribed to a collection
  Future<bool> isSubscribed({
    required String userId,
    required String ownerEmail,
    required String collectionId,
  }) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Subscriptions')
        .where('collectionId', isEqualTo: collectionId)
        .where('ownerEmail', isEqualTo: ownerEmail)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Subscribe to a collection
  Future<String> subscribe({
    required String userId,
    required String ownerEmail,
    required String collectionId,
    required String collectionName,
    String? collectionDescription,
    required String ownerDisplayName,
    int markerCount = 0,
    String? coverImageUrl,
  }) async {
    // Check if already subscribed
    if (await isSubscribed(
      userId: userId,
      ownerEmail: ownerEmail,
      collectionId: collectionId,
    )) {
      throw Exception('Already subscribed to this collection');
    }

    final subscription = CollectionSubscriptionModel(
      id: '',
      collectionId: collectionId,
      ownerEmail: ownerEmail,
      ownerDisplayName: ownerDisplayName,
      collectionName: collectionName,
      collectionDescription: collectionDescription,
      subscribedAt: DateTime.now(),
      markerCount: markerCount,
      coverImageUrl: coverImageUrl,
    );

    final docRef = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Subscriptions')
        .add(subscription.toMap());

    // Increment subscriber count on the original collection
    await firestoreService
        .collection('Users')
        .doc(ownerEmail)
        .collection('Collections')
        .doc(collectionId)
        .update({
      'subscriberCount': FieldValue.increment(1),
    });

    debugPrint('Subscribed to collection: $collectionId');
    return docRef.id;
  }

  /// Unsubscribe from a collection
  Future<void> unsubscribe({
    required String userId,
    required String subscriptionId,
    required String ownerEmail,
    required String collectionId,
  }) async {
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Subscriptions')
        .doc(subscriptionId)
        .delete();

    // Decrement subscriber count on the original collection
    try {
      await firestoreService
          .collection('Users')
          .doc(ownerEmail)
          .collection('Collections')
          .doc(collectionId)
          .update({
        'subscriberCount': FieldValue.increment(-1),
      });
    } catch (e) {
      // Collection may have been deleted
      debugPrint('Could not update subscriber count: $e');
    }

    debugPrint('Unsubscribed from collection: $collectionId');
  }

  /// Get subscription by collection ID
  Future<CollectionSubscriptionModel?> getSubscriptionByCollectionId({
    required String userId,
    required String ownerEmail,
    required String collectionId,
  }) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Subscriptions')
        .where('collectionId', isEqualTo: collectionId)
        .where('ownerEmail', isEqualTo: ownerEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return CollectionSubscriptionModel.fromFirestore(snapshot.docs.first);
  }

  /// Sync subscription data when collection is updated
  /// Call this to update denormalized data
  Future<void> syncSubscriptionData({
    required String collectionId,
    required String ownerEmail,
    String? collectionName,
    String? collectionDescription,
    int? markerCount,
    String? coverImageUrl,
  }) async {
    // This would typically be done via Cloud Functions for efficiency
    // For now, we log a reminder
    debugPrint(
        'Subscription sync needed for collection: $collectionId. Consider using Cloud Functions.');
  }

  /// Get collection count for a user
  Future<int> getCollectionCount(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Collections')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Get subscription count for a user
  Future<int> getSubscriptionCount(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Subscriptions')
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}
