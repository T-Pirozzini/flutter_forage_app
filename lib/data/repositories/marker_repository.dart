import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/core/constants/firestore_collections.dart';
import 'package:flutter_forager_app/core/utils/location_obfuscation.dart';
import 'package:flutter_forager_app/data/repositories/base_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
import 'package:flutter_forager_app/data/models/location_sharing_info.dart';

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
  /// Only returns markers with visibility set to 'public'
  Future<List<MarkerModel>> getPublicMarkers() async {
    try {
      final snapshot = await firestoreService
          .collection(collectionPath)
          .where('visibility', isEqualTo: MarkerVisibility.public.name)
          .orderBy(FirestoreFields.timestamp, descending: true)
          .get();

      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching public markers: $e');
      rethrow;
    }
  }

  /// Stream all public markers (real-time)
  /// Only returns markers with visibility set to 'public'
  /// [limit] controls max markers loaded (default 100 for performance)
  Stream<List<MarkerModel>> streamPublicMarkers({int limit = 100}) {
    return firestoreService
        .collection(collectionPath)
        .where('visibility', isEqualTo: MarkerVisibility.public.name)
        .orderBy(FirestoreFields.timestamp, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Stream markers visible to a specific user
  ///
  /// Returns markers that the user can see based on visibility settings:
  /// - All markers owned by the user
  /// - All public markers
  /// - Close-friends-only markers if viewer is a close friend of the owner
  /// - Friends-only markers if the user is friends with the owner
  /// - Specific markers if the user is in the allowedViewers list
  ///
  /// [viewerEmail] is the email of the user viewing markers
  /// [friendEmails] is the list of the viewer's friends' emails
  /// [closeFriendOfViewerEmails] is the set of owner emails who marked viewer as close friend
  Stream<List<MarkerModel>> streamVisibleMarkers({
    required String viewerEmail,
    required List<String> friendEmails,
    Set<String> closeFriendOfViewerEmails = const {},
    int limit = 100,
  }) {
    return firestoreService
        .collection(collectionPath)
        .orderBy(FirestoreFields.timestamp, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final allMarkers = snapshot.docs.map((doc) => fromFirestore(doc)).toList();

      // Filter markers based on visibility
      return allMarkers.where((marker) {
        // Always show user's own markers
        if (marker.markerOwner == viewerEmail) return true;

        switch (marker.visibility) {
          case MarkerVisibility.public:
            return true;
          case MarkerVisibility.private:
            return false; // Only owner can see
          case MarkerVisibility.closeFriends:
            // Visible if the owner considers viewer a close friend
            return closeFriendOfViewerEmails.contains(marker.markerOwner);
          case MarkerVisibility.friends:
            return friendEmails.contains(marker.markerOwner);
          case MarkerVisibility.specific:
            return marker.allowedViewers.contains(viewerEmail);
        }
      }).toList();
    });
  }

  /// Get markers visible to a specific user (one-time fetch)
  Future<List<MarkerModel>> getVisibleMarkers({
    required String viewerEmail,
    required List<String> friendEmails,
    Set<String> closeFriendOfViewerEmails = const {},
  }) async {
    try {
      final snapshot = await firestoreService
          .collection(collectionPath)
          .orderBy(FirestoreFields.timestamp, descending: true)
          .get();

      final allMarkers = snapshot.docs.map((doc) => fromFirestore(doc)).toList();

      // Filter markers based on visibility
      return allMarkers.where((marker) {
        // Always show user's own markers
        if (marker.markerOwner == viewerEmail) return true;

        switch (marker.visibility) {
          case MarkerVisibility.public:
            return true;
          case MarkerVisibility.private:
            return false;
          case MarkerVisibility.closeFriends:
            // Visible if the owner considers viewer a close friend
            return closeFriendOfViewerEmails.contains(marker.markerOwner);
          case MarkerVisibility.friends:
            return friendEmails.contains(marker.markerOwner);
          case MarkerVisibility.specific:
            return marker.allowedViewers.contains(viewerEmail);
        }
      }).toList();
    } catch (e) {
      debugPrint('Error fetching visible markers: $e');
      rethrow;
    }
  }

  /// Update marker visibility
  Future<void> updateVisibility({
    required String markerId,
    required MarkerVisibility visibility,
    List<String> allowedViewers = const [],
  }) async {
    await firestoreService
        .collection(collectionPath)
        .doc(markerId)
        .update({
      'visibility': visibility.name,
      'allowedViewers': allowedViewers,
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

  // ============ LOCATION OBFUSCATION ============

  /// Stream markers visible to a user with location obfuscation applied.
  ///
  /// Regular friends see obfuscated locations (~500m radius).
  /// Close friends see precise locations.
  /// User's own markers always show precise locations.
  ///
  /// [viewerEmail] - Email of the user viewing markers
  /// [friendEmails] - List of all friend emails
  /// [closeFriendEmails] - Set of close friend emails (see precise locations)
  Stream<List<MarkerModel>> streamVisibleMarkersWithObfuscation({
    required String viewerEmail,
    required List<String> friendEmails,
    required Set<String> closeFriendEmails,
    int limit = 100,
  }) {
    return streamVisibleMarkers(
      viewerEmail: viewerEmail,
      friendEmails: friendEmails,
      limit: limit,
    ).map((markers) {
      return LocationObfuscation.obfuscateMarkersForViewer(
        markers: markers,
        viewerEmail: viewerEmail,
        closeFriendEmails: closeFriendEmails,
      );
    });
  }

  /// Get visible markers with location obfuscation applied (one-time fetch).
  ///
  /// Regular friends see obfuscated locations (~500m radius).
  /// Close friends see precise locations.
  Future<List<MarkerModel>> getVisibleMarkersWithObfuscation({
    required String viewerEmail,
    required List<String> friendEmails,
    required Set<String> closeFriendEmails,
  }) async {
    final markers = await getVisibleMarkers(
      viewerEmail: viewerEmail,
      friendEmails: friendEmails,
    );

    return LocationObfuscation.obfuscateMarkersForViewer(
      markers: markers,
      viewerEmail: viewerEmail,
      closeFriendEmails: closeFriendEmails,
    );
  }

  /// Stream a specific user's markers with obfuscation based on viewer relationship.
  ///
  /// Used when viewing a friend's locations list.
  /// Close friends see precise locations, regular friends see obfuscated.
  Stream<List<MarkerModel>> streamUserMarkersWithObfuscation({
    required String ownerEmail,
    required String viewerEmail,
    required bool isCloseFriend,
  }) {
    return streamByUserId(ownerEmail).map((markers) {
      if (ownerEmail == viewerEmail || isCloseFriend) {
        // Owner or close friend - show precise locations
        return markers;
      }
      // Regular friend - obfuscate locations
      return markers.map((marker) {
        return LocationObfuscation.obfuscateMarker(marker);
      }).toList();
    });
  }

  /// Get a specific user's markers with obfuscation (one-time fetch).
  Future<List<MarkerModel>> getUserMarkersWithObfuscation({
    required String ownerEmail,
    required String viewerEmail,
    required bool isCloseFriend,
  }) async {
    final markers = await getByUserId(ownerEmail);

    if (ownerEmail == viewerEmail || isCloseFriend) {
      return markers;
    }

    return markers.map((marker) {
      return LocationObfuscation.obfuscateMarker(marker);
    }).toList();
  }

  // ============ LOCATION SHARING INFO ============

  /// Get location sharing information between two users.
  ///
  /// Returns how many of the owner's locations are shared with or hidden from
  /// the viewer based on visibility settings.
  ///
  /// [ownerEmail] - Email of the user who owns the markers
  /// [viewerEmail] - Email of the user viewing (to check visibility)
  /// [isFriend] - Whether the viewer is a friend of the owner
  Future<LocationSharingInfo> getLocationSharingInfo({
    required String ownerEmail,
    required String viewerEmail,
  }) async {
    try {
      final markers = await getByUserId(ownerEmail);

      if (markers.isEmpty) {
        return const LocationSharingInfo.empty();
      }

      int sharedCount = 0;
      int hiddenCount = 0;

      for (final marker in markers) {
        final isVisible = _isMarkerVisibleToViewer(
          marker: marker,
          viewerEmail: viewerEmail,
        );

        if (isVisible) {
          sharedCount++;
        } else {
          hiddenCount++;
        }
      }

      return LocationSharingInfo(
        totalLocations: markers.length,
        sharedWithViewer: sharedCount,
        hiddenFromViewer: hiddenCount,
      );
    } catch (e) {
      debugPrint('Error getting location sharing info: $e');
      return const LocationSharingInfo.empty();
    }
  }

  /// Stream location sharing info (updates when markers change).
  Stream<LocationSharingInfo> streamLocationSharingInfo({
    required String ownerEmail,
    required String viewerEmail,
  }) {
    return streamByUserId(ownerEmail).map((markers) {
      if (markers.isEmpty) {
        return const LocationSharingInfo.empty();
      }

      int sharedCount = 0;
      int hiddenCount = 0;

      for (final marker in markers) {
        final isVisible = _isMarkerVisibleToViewer(
          marker: marker,
          viewerEmail: viewerEmail,
        );

        if (isVisible) {
          sharedCount++;
        } else {
          hiddenCount++;
        }
      }

      return LocationSharingInfo(
        totalLocations: markers.length,
        sharedWithViewer: sharedCount,
        hiddenFromViewer: hiddenCount,
      );
    });
  }

  /// Find a marker by matching owner and coordinates.
  ///
  /// This is a fallback method for when markerId doesn't match a marker
  /// (e.g., bookmarks created from community posts store postId as markerId).
  ///
  /// Returns the first marker that matches owner, latitude, and longitude.
  Future<MarkerModel?> findByOwnerAndCoordinates({
    required String ownerEmail,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final markers = await getByUserId(ownerEmail);

      // Find marker with matching coordinates (within small tolerance for floating point)
      const tolerance = 0.0001; // About 11 meters
      for (final marker in markers) {
        if ((marker.latitude - latitude).abs() < tolerance &&
            (marker.longitude - longitude).abs() < tolerance) {
          return marker;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error finding marker by coordinates: $e');
      return null;
    }
  }

  /// Check if a marker is visible to a specific viewer.
  ///
  /// [isViewerCloseFriendOfOwner] should be true if the viewer is marked as
  /// a close friend by the marker owner.
  bool _isMarkerVisibleToViewer({
    required MarkerModel marker,
    required String viewerEmail,
    bool isViewerCloseFriendOfOwner = false,
  }) {
    // Owner can always see their own markers
    if (marker.markerOwner == viewerEmail) return true;

    switch (marker.visibility) {
      case MarkerVisibility.public:
        return true;
      case MarkerVisibility.private:
        return false;
      case MarkerVisibility.closeFriends:
        // Visible only if the owner considers viewer a close friend
        return isViewerCloseFriendOfOwner;
      case MarkerVisibility.friends:
        // For friends visibility, the caller should be a friend
        // This method is called in friend context, so return true
        return true;
      case MarkerVisibility.specific:
        return marker.allowedViewers.contains(viewerEmail);
    }
  }
}
