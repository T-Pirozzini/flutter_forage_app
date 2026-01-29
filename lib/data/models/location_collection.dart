import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a named collection of locations stored in the user's Collections subcollection.
///
/// Stored at: /Users/{userId}/Collections/{collectionId}
/// Allows users to organize markers into themed groups that can be shared with friends.
class LocationCollectionModel {
  /// Unique collection ID
  final String id;

  /// Collection name (e.g., "Best Mushroom Spots", "Spring Berries")
  final String name;

  /// Optional description of the collection
  final String? description;

  /// Whether this collection is publicly shareable
  final bool isPublic;

  /// When the collection was created
  final DateTime createdAt;

  /// When the collection was last updated
  final DateTime? updatedAt;

  /// List of marker IDs in this collection
  final List<String> markerIds;

  /// Owner's email (used when viewing subscribed collections)
  final String ownerEmail;

  /// Owner's display name (denormalized for display)
  final String ownerDisplayName;

  /// Number of subscribers (denormalized for display)
  final int subscriberCount;

  /// Cover image URL (first marker's image or custom)
  final String? coverImageUrl;

  LocationCollectionModel({
    required this.id,
    required this.name,
    this.description,
    this.isPublic = false,
    required this.createdAt,
    this.updatedAt,
    this.markerIds = const [],
    this.ownerEmail = '',
    this.ownerDisplayName = '',
    this.subscriberCount = 0,
    this.coverImageUrl,
  });

  /// Create from Firestore document
  factory LocationCollectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationCollectionModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      isPublic: data['isPublic'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      markerIds: List<String>.from(data['markerIds'] ?? []),
      ownerEmail: data['ownerEmail'] ?? '',
      ownerDisplayName: data['ownerDisplayName'] ?? '',
      subscriberCount: data['subscriberCount'] ?? 0,
      coverImageUrl: data['coverImageUrl'],
    );
  }

  /// Create from map
  factory LocationCollectionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return LocationCollectionModel(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      isPublic: map['isPublic'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      markerIds: List<String>.from(map['markerIds'] ?? []),
      ownerEmail: map['ownerEmail'] ?? '',
      ownerDisplayName: map['ownerDisplayName'] ?? '',
      subscriberCount: map['subscriberCount'] ?? 0,
      coverImageUrl: map['coverImageUrl'],
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'markerIds': markerIds,
      'ownerEmail': ownerEmail,
      'ownerDisplayName': ownerDisplayName,
      'subscriberCount': subscriberCount,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
    };
  }

  /// Number of markers in this collection
  int get markerCount => markerIds.length;

  /// Whether this collection is empty
  bool get isEmpty => markerIds.isEmpty;

  /// Whether this collection has markers
  bool get isNotEmpty => markerIds.isNotEmpty;

  /// Create a copy with modified fields
  LocationCollectionModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? markerIds,
    String? ownerEmail,
    String? ownerDisplayName,
    int? subscriberCount,
    String? coverImageUrl,
  }) {
    return LocationCollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      markerIds: markerIds ?? this.markerIds,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerDisplayName: ownerDisplayName ?? this.ownerDisplayName,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationCollectionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LocationCollectionModel(id: $id, name: $name, markerCount: $markerCount, isPublic: $isPublic)';
  }
}
