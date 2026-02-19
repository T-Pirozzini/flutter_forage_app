import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of in-app notifications
enum NotificationType {
  friendRequest,
  friendAccepted,
  postLike,
  postComment,
  achievement,
  levelUp,
}

/// Model representing a notification stored in Firestore.
///
/// Stored at: Users/{email}/Notifications/{notificationId}
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? fromEmail;
  final String? fromDisplayName;
  final String? postId;
  final String? requestId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.fromEmail,
    this.fromDisplayName,
    this.postId,
    this.requestId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      type: _parseType(data['type'] as String? ?? ''),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      fromEmail: data['fromEmail'] as String?,
      fromDisplayName: data['fromDisplayName'] as String?,
      postId: data['postId'] as String?,
      requestId: data['requestId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'body': body,
      'fromEmail': fromEmail,
      'fromDisplayName': fromDisplayName,
      'postId': postId,
      'requestId': requestId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      fromEmail: fromEmail,
      fromDisplayName: fromDisplayName,
      postId: postId,
      requestId: requestId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  static NotificationType _parseType(String value) {
    switch (value) {
      case 'friend_request':
      case 'friendRequest':
        return NotificationType.friendRequest;
      case 'friend_accepted':
      case 'friendAccepted':
        return NotificationType.friendAccepted;
      case 'post_like':
      case 'postLike':
        return NotificationType.postLike;
      case 'post_comment':
      case 'postComment':
        return NotificationType.postComment;
      case 'achievement':
        return NotificationType.achievement;
      case 'level_up':
      case 'levelUp':
        return NotificationType.levelUp;
      default:
        return NotificationType.postLike;
    }
  }
}
