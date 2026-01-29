import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of activity that can appear in the feed
enum ActivityType {
  /// Friend added a new marker
  newMarker,

  /// Friend bookmarked a location
  bookmark,

  /// Friend created/updated a collection
  collection,

  /// A new user joined as friend
  friendJoined,

  /// Friend shared a collection publicly
  collectionShared,

  /// Status update on a marker
  statusUpdate;

  /// Convert from string (for Firestore)
  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ActivityType.newMarker,
    );
  }

  /// Human-readable description
  String get displayName {
    switch (this) {
      case ActivityType.newMarker:
        return 'added a new location';
      case ActivityType.bookmark:
        return 'bookmarked a location';
      case ActivityType.collection:
        return 'updated a collection';
      case ActivityType.friendJoined:
        return 'became your friend';
      case ActivityType.collectionShared:
        return 'shared a collection';
      case ActivityType.statusUpdate:
        return 'updated a status';
    }
  }
}

/// Represents an activity item in the user's activity feed.
///
/// Stored at: /Users/{userId}/ActivityFeed/{activityId}
/// Activity items are pushed (fan-out) to each friend's feed when actions occur.
class ActivityItemModel {
  /// Unique activity ID
  final String id;

  /// Type of activity
  final ActivityType type;

  /// Email of the user who performed the action
  final String actorEmail;

  /// Display name of the actor (denormalized)
  final String actorName;

  /// Profile photo URL of the actor (denormalized)
  final String? actorPhotoUrl;

  /// ID of the target entity (marker, collection, etc.)
  final String? targetId;

  /// Name/title of the target entity (denormalized)
  final String? targetName;

  /// Type of marker if applicable (for icon display)
  final String? markerType;

  /// Location coordinates if applicable
  final double? latitude;
  final double? longitude;

  /// When the activity occurred
  final DateTime createdAt;

  /// Whether the user has seen this activity
  final bool read;

  /// Additional context or preview text
  final String? preview;

  ActivityItemModel({
    required this.id,
    required this.type,
    required this.actorEmail,
    required this.actorName,
    this.actorPhotoUrl,
    this.targetId,
    this.targetName,
    this.markerType,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.read = false,
    this.preview,
  });

  /// Create from Firestore document
  factory ActivityItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityItemModel(
      id: doc.id,
      type: ActivityType.fromString(data['type'] ?? 'newMarker'),
      actorEmail: data['actorEmail'] ?? '',
      actorName: data['actorName'] ?? '',
      actorPhotoUrl: data['actorPhotoUrl'],
      targetId: data['targetId'],
      targetName: data['targetName'],
      markerType: data['markerType'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      read: data['read'] ?? false,
      preview: data['preview'],
    );
  }

  /// Create from map
  factory ActivityItemModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ActivityItemModel(
      id: id ?? map['id'] ?? '',
      type: ActivityType.fromString(map['type'] ?? 'newMarker'),
      actorEmail: map['actorEmail'] ?? '',
      actorName: map['actorName'] ?? '',
      actorPhotoUrl: map['actorPhotoUrl'],
      targetId: map['targetId'],
      targetName: map['targetName'],
      markerType: map['markerType'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      read: map['read'] ?? false,
      preview: map['preview'],
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'actorEmail': actorEmail,
      'actorName': actorName,
      if (actorPhotoUrl != null) 'actorPhotoUrl': actorPhotoUrl,
      if (targetId != null) 'targetId': targetId,
      if (targetName != null) 'targetName': targetName,
      if (markerType != null) 'markerType': markerType,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
      if (preview != null) 'preview': preview,
    };
  }

  /// Whether this activity is unread
  bool get isUnread => !read;

  /// Whether this activity has location data
  bool get hasLocation => latitude != null && longitude != null;

  /// Create a copy with modified fields
  ActivityItemModel copyWith({
    String? id,
    ActivityType? type,
    String? actorEmail,
    String? actorName,
    String? actorPhotoUrl,
    String? targetId,
    String? targetName,
    String? markerType,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    bool? read,
    String? preview,
  }) {
    return ActivityItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      actorEmail: actorEmail ?? this.actorEmail,
      actorName: actorName ?? this.actorName,
      actorPhotoUrl: actorPhotoUrl ?? this.actorPhotoUrl,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      markerType: markerType ?? this.markerType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      preview: preview ?? this.preview,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ActivityItemModel(id: $id, type: ${type.name}, actor: $actorName, target: $targetName)';
  }
}
