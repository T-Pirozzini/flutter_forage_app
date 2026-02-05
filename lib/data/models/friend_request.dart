import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a friend request
enum FriendRequestStatus {
  pending,
  accepted,
  declined;

  /// Convert from string (for Firestore)
  static FriendRequestStatus fromString(String value) {
    return FriendRequestStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => FriendRequestStatus.pending,
    );
  }
}

/// Represents a friend request stored in the user's FriendRequests subcollection.
///
/// Stored at: /Users/{userId}/FriendRequests/{requestId}
/// Both sender and receiver have a copy for efficient querying.
class FriendRequestModel {
  /// Unique request ID
  final String id;

  /// Email of the user who sent the request
  final String fromEmail;

  /// Display name of sender (denormalized)
  final String fromDisplayName;

  /// Profile photo URL of sender (denormalized)
  final String? fromPhotoUrl;

  /// Email of the user receiving the request
  final String toEmail;

  /// Display name of receiver (denormalized)
  final String toDisplayName;

  /// Optional intro message from sender (150 char max)
  final String? message;

  /// Current status of the request
  final FriendRequestStatus status;

  /// When the request was created
  final DateTime createdAt;

  /// When the request was responded to (accepted/declined)
  final DateTime? respondedAt;

  FriendRequestModel({
    required this.id,
    required this.fromEmail,
    required this.fromDisplayName,
    this.fromPhotoUrl,
    required this.toEmail,
    this.toDisplayName = '',
    this.message,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  /// Create from Firestore document
  factory FriendRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequestModel(
      id: doc.id,
      fromEmail: data['fromEmail'] ?? '',
      fromDisplayName: data['fromDisplayName'] ?? '',
      fromPhotoUrl: data['fromPhotoUrl'],
      toEmail: data['toEmail'] ?? '',
      toDisplayName: data['toDisplayName'] ?? '',
      message: data['message'],
      status: FriendRequestStatus.fromString(data['status'] ?? 'pending'),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create from map
  factory FriendRequestModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return FriendRequestModel(
      id: id ?? map['id'] ?? '',
      fromEmail: map['fromEmail'] ?? '',
      fromDisplayName: map['fromDisplayName'] ?? '',
      fromPhotoUrl: map['fromPhotoUrl'],
      toEmail: map['toEmail'] ?? '',
      toDisplayName: map['toDisplayName'] ?? '',
      message: map['message'],
      status: FriendRequestStatus.fromString(map['status'] ?? 'pending'),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'fromEmail': fromEmail,
      'fromDisplayName': fromDisplayName,
      if (fromPhotoUrl != null) 'fromPhotoUrl': fromPhotoUrl,
      'toEmail': toEmail,
      'toDisplayName': toDisplayName,
      if (message != null) 'message': message,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      if (respondedAt != null) 'respondedAt': Timestamp.fromDate(respondedAt!),
    };
  }

  /// Whether this request is still pending
  bool get isPending => status == FriendRequestStatus.pending;

  /// Whether this request has been accepted
  bool get isAccepted => status == FriendRequestStatus.accepted;

  /// Whether this request has been declined
  bool get isDeclined => status == FriendRequestStatus.declined;

  /// Create a copy with modified fields
  FriendRequestModel copyWith({
    String? id,
    String? fromEmail,
    String? fromDisplayName,
    String? fromPhotoUrl,
    String? toEmail,
    String? toDisplayName,
    String? message,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendRequestModel(
      id: id ?? this.id,
      fromEmail: fromEmail ?? this.fromEmail,
      fromDisplayName: fromDisplayName ?? this.fromDisplayName,
      fromPhotoUrl: fromPhotoUrl ?? this.fromPhotoUrl,
      toEmail: toEmail ?? this.toEmail,
      toDisplayName: toDisplayName ?? this.toDisplayName,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendRequestModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FriendRequestModel(id: $id, from: $fromEmail, to: $toEmail, status: ${status.name})';
  }
}
