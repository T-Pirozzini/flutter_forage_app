import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a subscription to another user's collection.
///
/// Stored at: /Users/{userId}/Subscriptions/{subscriptionId}
/// Denormalizes collection data for efficient display without additional lookups.
class CollectionSubscriptionModel {
  /// Unique subscription ID
  final String id;

  /// ID of the subscribed collection
  final String collectionId;

  /// Email of the collection owner
  final String ownerEmail;

  /// Display name of the collection owner (denormalized)
  final String ownerDisplayName;

  /// Name of the collection (denormalized)
  final String collectionName;

  /// Description of the collection (denormalized)
  final String? collectionDescription;

  /// When the subscription was created
  final DateTime subscribedAt;

  /// Number of markers in the collection (denormalized)
  final int markerCount;

  /// Cover image URL (denormalized)
  final String? coverImageUrl;

  CollectionSubscriptionModel({
    required this.id,
    required this.collectionId,
    required this.ownerEmail,
    this.ownerDisplayName = '',
    required this.collectionName,
    this.collectionDescription,
    required this.subscribedAt,
    this.markerCount = 0,
    this.coverImageUrl,
  });

  /// Create from Firestore document
  factory CollectionSubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CollectionSubscriptionModel(
      id: doc.id,
      collectionId: data['collectionId'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      ownerDisplayName: data['ownerDisplayName'] ?? '',
      collectionName: data['collectionName'] ?? '',
      collectionDescription: data['collectionDescription'],
      subscribedAt: data['subscribedAt'] != null
          ? (data['subscribedAt'] as Timestamp).toDate()
          : DateTime.now(),
      markerCount: data['markerCount'] ?? 0,
      coverImageUrl: data['coverImageUrl'],
    );
  }

  /// Create from map
  factory CollectionSubscriptionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CollectionSubscriptionModel(
      id: id ?? map['id'] ?? '',
      collectionId: map['collectionId'] ?? '',
      ownerEmail: map['ownerEmail'] ?? '',
      ownerDisplayName: map['ownerDisplayName'] ?? '',
      collectionName: map['collectionName'] ?? '',
      collectionDescription: map['collectionDescription'],
      subscribedAt: map['subscribedAt'] != null
          ? (map['subscribedAt'] as Timestamp).toDate()
          : DateTime.now(),
      markerCount: map['markerCount'] ?? 0,
      coverImageUrl: map['coverImageUrl'],
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'collectionId': collectionId,
      'ownerEmail': ownerEmail,
      'ownerDisplayName': ownerDisplayName,
      'collectionName': collectionName,
      if (collectionDescription != null) 'collectionDescription': collectionDescription,
      'subscribedAt': Timestamp.fromDate(subscribedAt),
      'markerCount': markerCount,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
    };
  }

  /// Create a copy with modified fields
  CollectionSubscriptionModel copyWith({
    String? id,
    String? collectionId,
    String? ownerEmail,
    String? ownerDisplayName,
    String? collectionName,
    String? collectionDescription,
    DateTime? subscribedAt,
    int? markerCount,
    String? coverImageUrl,
  }) {
    return CollectionSubscriptionModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerDisplayName: ownerDisplayName ?? this.ownerDisplayName,
      collectionName: collectionName ?? this.collectionName,
      collectionDescription: collectionDescription ?? this.collectionDescription,
      subscribedAt: subscribedAt ?? this.subscribedAt,
      markerCount: markerCount ?? this.markerCount,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionSubscriptionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CollectionSubscriptionModel(id: $id, collectionName: $collectionName, ownerEmail: $ownerEmail)';
  }
}
