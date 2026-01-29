import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/data/models/bookmark.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';

/// Repository for managing user bookmarks (saved locations).
///
/// Uses Firestore subcollection for scalability:
/// - /Users/{userId}/Bookmarks/{bookmarkId}
///
/// Bookmarks denormalize marker data for efficient display without additional lookups.
class BookmarkRepository {
  final FirestoreService firestoreService;

  BookmarkRepository({required this.firestoreService});

  /// Stream all bookmarks for a user
  Stream<List<BookmarkModel>> streamBookmarks(String userId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Bookmarks')
        .orderBy('bookmarkedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookmarkModel.fromFirestore(doc)).toList();
    });
  }

  /// Get all bookmarks for a user (one-time fetch)
  Future<List<BookmarkModel>> getBookmarks(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Bookmarks')
        .orderBy('bookmarkedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => BookmarkModel.fromFirestore(doc)).toList();
  }

  /// Get bookmarks by forage type
  Stream<List<BookmarkModel>> streamBookmarksByType(String userId, String type) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Bookmarks')
        .where('type', isEqualTo: type)
        .orderBy('bookmarkedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookmarkModel.fromFirestore(doc)).toList();
    });
  }

  /// Check if a marker is bookmarked by the user
  Future<bool> isBookmarked(String userId, String markerId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Bookmarks')
        .where('markerId', isEqualTo: markerId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Stream bookmark status for a specific marker
  Stream<bool> streamIsBookmarked(String userId, String markerId) {
    return firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Bookmarks')
        .where('markerId', isEqualTo: markerId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Add a bookmark for a marker
  ///
  /// Denormalizes marker data for efficient display.
  Future<String> addBookmark({
    required String userId,
    required MarkerModel marker,
    String? notes,
  }) async {
    // Check if already bookmarked
    if (await isBookmarked(userId, marker.id)) {
      throw Exception('Marker already bookmarked');
    }

    final bookmark = BookmarkModel(
      id: '',
      markerId: marker.id,
      markerOwner: marker.markerOwner,
      markerName: marker.name,
      markerDescription: marker.description,
      latitude: marker.latitude,
      longitude: marker.longitude,
      type: marker.type,
      bookmarkedAt: DateTime.now(),
      notes: notes,
      imageUrl: marker.imageUrl.isNotEmpty ? marker.imageUrl : null,
    );

    final docRef = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Bookmarks')
        .add(bookmark.toMap());

    debugPrint('Bookmark added: ${marker.id} for user $userId');
    return docRef.id;
  }

  /// Add a bookmark from raw marker data (for community feed)
  Future<String> addBookmarkFromData({
    required String userId,
    required String markerId,
    required String markerOwner,
    required String markerName,
    required String markerDescription,
    required double latitude,
    required double longitude,
    required String type,
    String? imageUrl,
    String? notes,
  }) async {
    // Check if already bookmarked
    if (await isBookmarked(userId, markerId)) {
      throw Exception('Marker already bookmarked');
    }

    final bookmark = BookmarkModel(
      id: '',
      markerId: markerId,
      markerOwner: markerOwner,
      markerName: markerName,
      markerDescription: markerDescription,
      latitude: latitude,
      longitude: longitude,
      type: type,
      bookmarkedAt: DateTime.now(),
      notes: notes,
      imageUrl: imageUrl,
    );

    final docRef = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Bookmarks')
        .add(bookmark.toMap());

    debugPrint('Bookmark added: $markerId for user $userId');
    return docRef.id;
  }

  /// Remove a bookmark by bookmark ID
  Future<void> removeBookmark(String userId, String bookmarkId) async {
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Bookmarks')
        .doc(bookmarkId)
        .delete();

    debugPrint('Bookmark removed: $bookmarkId for user $userId');
  }

  /// Remove a bookmark by marker ID
  Future<void> removeBookmarkByMarkerId(String userId, String markerId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Bookmarks')
        .where('markerId', isEqualTo: markerId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    debugPrint('Bookmark removed for marker: $markerId');
  }

  /// Update bookmark notes
  Future<void> updateNotes(String userId, String bookmarkId, String? notes) async {
    await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Bookmarks')
        .doc(bookmarkId)
        .update({'notes': notes});
  }

  /// Get bookmark by marker ID (if exists)
  Future<BookmarkModel?> getBookmarkByMarkerId(String userId, String markerId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Bookmarks')
        .where('markerId', isEqualTo: markerId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return BookmarkModel.fromFirestore(snapshot.docs.first);
  }

  /// Get bookmark count for a user
  Future<int> getBookmarkCount(String userId) async {
    final snapshot = await firestoreService
        .collection('Users')
        .doc(userId)
        .collection('Bookmarks')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Search bookmarks by name or description
  Stream<List<BookmarkModel>> searchBookmarks(String userId, String query) {
    if (query.isEmpty) return streamBookmarks(userId);

    final queryLower = query.toLowerCase();

    return streamBookmarks(userId).map((bookmarks) {
      return bookmarks
          .where((bookmark) =>
              bookmark.markerName.toLowerCase().contains(queryLower) ||
              bookmark.markerDescription.toLowerCase().contains(queryLower) ||
              bookmark.type.toLowerCase().contains(queryLower) ||
              (bookmark.notes?.toLowerCase().contains(queryLower) ?? false))
          .toList();
    });
  }

  /// Toggle bookmark status for a marker
  ///
  /// Returns true if bookmark was added, false if removed.
  Future<bool> toggleBookmark({
    required String userId,
    required MarkerModel marker,
  }) async {
    final existing = await getBookmarkByMarkerId(userId, marker.id);

    if (existing != null) {
      await removeBookmark(userId, existing.id);
      return false;
    } else {
      await addBookmark(userId: userId, marker: marker);
      return true;
    }
  }

  /// Sync bookmark data when marker is updated
  ///
  /// Call this when a marker's details change to update all bookmarks.
  Future<void> syncBookmarkData({
    required String markerId,
    required String markerName,
    required String markerDescription,
    String? imageUrl,
  }) async {
    // This would typically be done via Cloud Functions for efficiency,
    // but for simplicity, we can do it client-side for small datasets.
    debugPrint('Bookmark sync requested for marker: $markerId');
    // Note: In production, implement via Cloud Functions to update
    // all users' bookmarks when a marker changes.
  }
}
