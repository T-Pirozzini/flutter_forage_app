import 'package:cloud_firestore/cloud_firestore.dart';

/// Categories for direct messages to admin
enum MessageCategory {
  bug,
  question,
  feature,
  other;

  String get displayName {
    switch (this) {
      case MessageCategory.bug:
        return 'Bug Report';
      case MessageCategory.question:
        return 'Question';
      case MessageCategory.feature:
        return 'Feature Request';
      case MessageCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case MessageCategory.bug:
        return 'bug_report';
      case MessageCategory.question:
        return 'help_outline';
      case MessageCategory.feature:
        return 'lightbulb_outline';
      case MessageCategory.other:
        return 'chat_bubble_outline';
    }
  }

  static MessageCategory fromString(String value) {
    return MessageCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageCategory.other,
    );
  }
}

/// Status of a direct message
enum MessageStatus {
  pending,
  read;

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageStatus.pending,
    );
  }
}

/// Model for private direct messages sent to admin
class DirectMessageModel {
  final String id;
  final String userId;
  final String userEmail;
  final String username;
  final String? profilePic;
  final MessageCategory category;
  final String message;
  final DateTime timestamp;
  final MessageStatus status;

  const DirectMessageModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.username,
    this.profilePic,
    required this.category,
    required this.message,
    required this.timestamp,
    this.status = MessageStatus.pending,
  });

  factory DirectMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DirectMessageModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      userEmail: data['userEmail']?.toString() ?? '',
      username: data['username']?.toString() ?? 'Unknown User',
      profilePic: data['profilePic']?.toString(),
      category: MessageCategory.fromString(data['category']?.toString() ?? 'other'),
      message: data['message']?.toString() ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      status: MessageStatus.fromString(data['status']?.toString() ?? 'pending'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'username': username,
      if (profilePic != null) 'profilePic': profilePic,
      'category': category.name,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
    };
  }

  DirectMessageModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? username,
    String? profilePic,
    MessageCategory? category,
    String? message,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return DirectMessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      username: username ?? this.username,
      profilePic: profilePic ?? this.profilePic,
      category: category ?? this.category,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  /// Get a preview of the message (first 50 chars)
  String get messagePreview {
    if (message.length <= 50) return message;
    return '${message.substring(0, 50)}...';
  }

  /// Check if the message has been read
  bool get isRead => status == MessageStatus.read;
}
