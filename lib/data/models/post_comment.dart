import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a comment on a community post.
///
/// Stored in subcollection: /Posts/{postId}/Comments/{commentId}
class PostCommentModel {
  final String id;
  final String userId;
  final String userEmail;
  final String username;
  final String? profilePic;
  final String text;
  final DateTime createdAt;

  const PostCommentModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.username,
    this.profilePic,
    required this.text,
    required this.createdAt,
  });

  factory PostCommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostCommentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      username: data['username'] ?? '',
      profilePic: data['profilePic'],
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create from legacy array format (for migration)
  factory PostCommentModel.fromMap(Map<String, dynamic> data, {String? id}) {
    DateTime createdAt;
    if (data['timestamp'] is Timestamp) {
      createdAt = (data['timestamp'] as Timestamp).toDate();
    } else if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdAt = DateTime.now();
    }

    return PostCommentModel(
      id: id ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      username: data['username'] ?? '',
      profilePic: data['profilePic'],
      text: data['text'] ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'username': username,
      if (profilePic != null) 'profilePic': profilePic,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  String toString() =>
      'PostCommentModel(id: $id, username: $username, text: ${text.length > 20 ? '${text.substring(0, 20)}...' : text})';
}
