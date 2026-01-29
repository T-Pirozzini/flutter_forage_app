import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a bookmarked location stored in the user's Bookmarks subcollection.
///
/// Stored at: /Users/{userId}/Bookmarks/{bookmarkId}
/// Denormalizes marker data for efficient display without additional lookups.
class BookmarkModel {
  /// Unique bookmark ID
  final String id;

  /// ID of the bookmarked marker
  final String markerId;

  /// Email of the marker's owner
  final String markerOwner;

  /// Name of the marker (denormalized)
  final String markerName;

  /// Marker description (denormalized)
  final String markerDescription;

  /// Latitude of the location
  final double latitude;

  /// Longitude of the location
  final double longitude;

  /// Forage type (e.g., 'mushrooms', 'berries')
  final String type;

  /// When the bookmark was created
  final DateTime bookmarkedAt;

  /// Optional user notes about this bookmark
  final String? notes;

  /// First image URL from the marker (denormalized for display)
  final String? imageUrl;

  BookmarkModel({
    required this.id,
    required this.markerId,
    required this.markerOwner,
    required this.markerName,
    this.markerDescription = '',
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.bookmarkedAt,
    this.notes,
    this.imageUrl,
  });

  /// Create from Firestore document
  factory BookmarkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookmarkModel(
      id: doc.id,
      markerId: data['markerId'] ?? '',
      markerOwner: data['markerOwner'] ?? '',
      markerName: data['markerName'] ?? '',
      markerDescription: data['markerDescription'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      type: data['type'] ?? 'other',
      bookmarkedAt: data['bookmarkedAt'] != null
          ? (data['bookmarkedAt'] as Timestamp).toDate()
          : DateTime.now(),
      notes: data['notes'],
      imageUrl: data['imageUrl'],
    );
  }

  /// Create from map
  factory BookmarkModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return BookmarkModel(
      id: id ?? map['id'] ?? '',
      markerId: map['markerId'] ?? '',
      markerOwner: map['markerOwner'] ?? '',
      markerName: map['markerName'] ?? '',
      markerDescription: map['markerDescription'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? 'other',
      bookmarkedAt: map['bookmarkedAt'] != null
          ? (map['bookmarkedAt'] as Timestamp).toDate()
          : DateTime.now(),
      notes: map['notes'],
      imageUrl: map['imageUrl'],
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'markerId': markerId,
      'markerOwner': markerOwner,
      'markerName': markerName,
      'markerDescription': markerDescription,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'bookmarkedAt': Timestamp.fromDate(bookmarkedAt),
      if (notes != null) 'notes': notes,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  /// Create a copy with modified fields
  BookmarkModel copyWith({
    String? id,
    String? markerId,
    String? markerOwner,
    String? markerName,
    String? markerDescription,
    double? latitude,
    double? longitude,
    String? type,
    DateTime? bookmarkedAt,
    String? notes,
    String? imageUrl,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      markerId: markerId ?? this.markerId,
      markerOwner: markerOwner ?? this.markerOwner,
      markerName: markerName ?? this.markerName,
      markerDescription: markerDescription ?? this.markerDescription,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BookmarkModel(id: $id, markerId: $markerId, markerName: $markerName, type: $type)';
  }
}
