// models/marker.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Visibility levels for markers
enum MarkerVisibility {
  /// Only the owner can see this marker
  private,

  /// Anyone can see this marker (community feed)
  public,

  /// Only the owner's friends can see this marker
  friends,

  /// Only specific users can see this marker
  specific;

  /// Convert from string (for Firestore)
  static MarkerVisibility fromString(String? value) {
    if (value == null) return MarkerVisibility.private;
    return MarkerVisibility.values.firstWhere(
      (v) => v.name == value,
      orElse: () => MarkerVisibility.private,
    );
  }

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case MarkerVisibility.private:
        return 'Private';
      case MarkerVisibility.public:
        return 'Public';
      case MarkerVisibility.friends:
        return 'Friends Only';
      case MarkerVisibility.specific:
        return 'Specific Friends';
    }
  }

  /// Description for UI
  String get description {
    switch (this) {
      case MarkerVisibility.private:
        return 'Only you can see this location';
      case MarkerVisibility.public:
        return 'Visible to everyone in the community';
      case MarkerVisibility.friends:
        return 'Visible to all your friends';
      case MarkerVisibility.specific:
        return 'Visible to selected friends only';
    }
  }
}

class MarkerComment {
  final String userId;
  final String userEmail;
  final String text;
  final DateTime timestamp;

  MarkerComment({
    required this.userId,
    required this.userEmail,
    required this.text,
    required this.timestamp,
  });

  factory MarkerComment.fromMap(Map<String, dynamic> map) {
    return MarkerComment(
      userId: map['userId'],
      userEmail: map['userEmail'],
      text: map['text'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'text': text,
      'timestamp': timestamp,
    };
  }
}

class MarkerStatusUpdate {
  final String status;
  final String userId;
  final String userEmail;
  final String? username;
  final DateTime timestamp;
  final String? notes;

  MarkerStatusUpdate({
    required this.status,
    required this.userId,
    required this.userEmail,
    this.username,
    required this.timestamp,
    this.notes,
  });

  factory MarkerStatusUpdate.fromMap(Map<String, dynamic> map) {
    return MarkerStatusUpdate(
      status: map['status'],
      userId: map['userId'],
      userEmail: map['userEmail'],
      username: map['username'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'userId': userId,
      'userEmail': userEmail,
      if (username != null) 'username': username,
      'timestamp': timestamp,
      if (notes != null) 'notes': notes,
    };
  }
}

class MarkerModel {
  final String id;
  final String name;
  final String description;
  final String type;
  final List<String> imageUrls;
  final String markerOwner;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String status;
  final List<MarkerComment> comments;
  final String currentStatus;
  final List<MarkerStatusUpdate> statusHistory;

  /// Visibility setting for this marker
  final MarkerVisibility visibility;

  /// List of user emails allowed to view this marker (when visibility is 'specific')
  final List<String> allowedViewers;

  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  /// Whether this marker is visible to the public
  bool get isPublic => visibility == MarkerVisibility.public;

  /// Whether this marker is private (owner only)
  bool get isPrivate => visibility == MarkerVisibility.private;

  /// Whether this marker is visible to friends only
  bool get isFriendsOnly => visibility == MarkerVisibility.friends;

  /// Whether this marker has specific viewer restrictions
  bool get hasSpecificViewers => visibility == MarkerVisibility.specific;

  MarkerModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.imageUrls,
    required this.markerOwner,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.status = 'active',
    this.comments = const [],
    required this.currentStatus,
    this.statusHistory = const [],
    this.visibility = MarkerVisibility.private,
    this.allowedViewers = const [],
  });

  factory MarkerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final location = data['location'] as Map<String, dynamic>;

    // Handle status history conversion
    List<MarkerStatusUpdate> history = [];
    if (data['statusHistory'] != null) {
      history = (data['statusHistory'] as List<dynamic>).map((item) {
        return MarkerStatusUpdate.fromMap(item as Map<String, dynamic>);
      }).toList();
    }

    // Handle comments conversion
    List<MarkerComment> comments = [];
    if (data['comments'] != null) {
      comments = (data['comments'] as List<dynamic>).map((comment) {
        return MarkerComment.fromMap(comment as Map<String, dynamic>);
      }).toList();
    }

    return MarkerModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'plant',
      imageUrls: List<String>.from(data['images'] ?? []),
      markerOwner: data['markerOwner'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      latitude: (location['latitude'] as num).toDouble(),
      longitude: (location['longitude'] as num).toDouble(),
      status: data['status'] ?? 'active',
      comments: comments,
      currentStatus: data['currentStatus'] ?? 'active',
      statusHistory: history,
      visibility: MarkerVisibility.fromString(data['visibility']),
      allowedViewers: List<String>.from(data['allowedViewers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'image': imageUrls,
      'markerOwner': markerOwner,
      'timestamp': timestamp,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'status': status,
      'comments': comments.map((c) => c.toMap()).toList(),
      'currentStatus': currentStatus,
      'statusHistory': statusHistory.map((s) => s.toMap()).toList(),
      'visibility': visibility.name,
      'allowedViewers': allowedViewers,
    };
  }

  /// Create a copy with modified fields
  MarkerModel copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    List<String>? imageUrls,
    String? markerOwner,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? status,
    List<MarkerComment>? comments,
    String? currentStatus,
    List<MarkerStatusUpdate>? statusHistory,
    MarkerVisibility? visibility,
    List<String>? allowedViewers,
  }) {
    return MarkerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      imageUrls: imageUrls ?? this.imageUrls,
      markerOwner: markerOwner ?? this.markerOwner,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      comments: comments ?? this.comments,
      currentStatus: currentStatus ?? this.currentStatus,
      statusHistory: statusHistory ?? this.statusHistory,
      visibility: visibility ?? this.visibility,
      allowedViewers: allowedViewers ?? this.allowedViewers,
    );
  }

  GeoPoint get geoPoint => GeoPoint(latitude, longitude);
}
