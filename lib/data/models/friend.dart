import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a friend relationship stored in the user's Friends subcollection.
///
/// Stored at: /Users/{userId}/Friends/{friendEmail}
/// Denormalizes friend data for efficient display without additional lookups.
class FriendModel {
  /// The friend's email (also serves as document ID)
  final String friendEmail;

  /// Display name (denormalized from friend's profile)
  final String displayName;

  /// Profile photo URL (denormalized from friend's profile)
  final String? photoUrl;

  /// When the friendship was established
  final DateTime addedAt;

  /// Whether this is a close friend (for visibility features)
  final bool closeFriend;

  FriendModel({
    required this.friendEmail,
    required this.displayName,
    this.photoUrl,
    required this.addedAt,
    this.closeFriend = false,
  });

  /// Create from Firestore document
  factory FriendModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendModel(
      friendEmail: data['friendEmail'] ?? doc.id,
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      addedAt: data['addedAt'] != null
          ? (data['addedAt'] as Timestamp).toDate()
          : DateTime.now(),
      closeFriend: data['closeFriend'] ?? false,
    );
  }

  /// Create from map (for batch operations)
  factory FriendModel.fromMap(Map<String, dynamic> map) {
    return FriendModel(
      friendEmail: map['friendEmail'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      addedAt: map['addedAt'] != null
          ? (map['addedAt'] as Timestamp).toDate()
          : DateTime.now(),
      closeFriend: map['closeFriend'] ?? false,
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'friendEmail': friendEmail,
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'addedAt': Timestamp.fromDate(addedAt),
      'closeFriend': closeFriend,
    };
  }

  /// Create a copy with modified fields
  FriendModel copyWith({
    String? friendEmail,
    String? displayName,
    String? photoUrl,
    DateTime? addedAt,
    bool? closeFriend,
  }) {
    return FriendModel(
      friendEmail: friendEmail ?? this.friendEmail,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      addedAt: addedAt ?? this.addedAt,
      closeFriend: closeFriend ?? this.closeFriend,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendModel &&
          runtimeType == other.runtimeType &&
          friendEmail == other.friendEmail;

  @override
  int get hashCode => friendEmail.hashCode;

  @override
  String toString() {
    return 'FriendModel(friendEmail: $friendEmail, displayName: $displayName, closeFriend: $closeFriend)';
  }
}
