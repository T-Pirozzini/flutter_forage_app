import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a one-way follow relationship.
///
/// Unlike Friends (mutual/bidirectional), Following is one-way.
/// Stored in `/Users/{userId}/Following/{targetEmail}`
class FollowingModel {
  final String followedEmail;
  final String displayName;
  final String? photoUrl;
  final DateTime followedAt;

  const FollowingModel({
    required this.followedEmail,
    required this.displayName,
    this.photoUrl,
    required this.followedAt,
  });

  /// Create from Firestore document
  factory FollowingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FollowingModel(
      followedEmail: doc.id,
      displayName: data['displayName'] ?? doc.id.split('@')[0],
      photoUrl: data['photoUrl'],
      followedAt: (data['followedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'followedEmail': followedEmail,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'followedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Copy with modifications
  FollowingModel copyWith({
    String? followedEmail,
    String? displayName,
    String? photoUrl,
    DateTime? followedAt,
  }) {
    return FollowingModel(
      followedEmail: followedEmail ?? this.followedEmail,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      followedAt: followedAt ?? this.followedAt,
    );
  }

  @override
  String toString() {
    return 'FollowingModel(followedEmail: $followedEmail, displayName: $displayName, followedAt: $followedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FollowingModel && other.followedEmail == followedEmail;
  }

  @override
  int get hashCode => followedEmail.hashCode;
}
