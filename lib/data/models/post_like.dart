import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a like on a community post.
///
/// Stored in subcollection: /Posts/{postId}/Likes/{likeId}
class PostLikeModel {
  final String id;
  final String userEmail;
  final DateTime createdAt;

  const PostLikeModel({
    required this.id,
    required this.userEmail,
    required this.createdAt,
  });

  factory PostLikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostLikeModel(
      id: doc.id,
      userEmail: data['userEmail'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userEmail': userEmail,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  String toString() => 'PostLikeModel(id: $id, userEmail: $userEmail)';
}
