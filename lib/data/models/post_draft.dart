import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a post draft
enum PostDraftStatus {
  draft,
  scheduled,
  published;

  static PostDraftStatus fromString(String value) {
    return PostDraftStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PostDraftStatus.draft,
    );
  }

  String get displayName {
    switch (this) {
      case PostDraftStatus.draft:
        return 'Draft';
      case PostDraftStatus.scheduled:
        return 'Scheduled';
      case PostDraftStatus.published:
        return 'Published';
    }
  }
}

/// Model for draft/scheduled community posts
///
/// Stored in `/Users/{userId}/PostDrafts/{draftId}`
class PostDraftModel {
  final String id;
  final String markerId;
  final String? markerName;
  final String? markerType;
  final String? communityDescription;
  final DateTime? scheduledFor;
  final PostDraftStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostDraftModel({
    required this.id,
    required this.markerId,
    this.markerName,
    this.markerType,
    this.communityDescription,
    this.scheduledFor,
    this.status = PostDraftStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostDraftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PostDraftModel(
      id: doc.id,
      markerId: data['markerId']?.toString() ?? '',
      markerName: data['markerName']?.toString(),
      markerType: data['markerType']?.toString(),
      communityDescription: data['communityDescription']?.toString(),
      scheduledFor: data['scheduledFor'] != null
          ? (data['scheduledFor'] as Timestamp).toDate()
          : null,
      status: PostDraftStatus.fromString(data['status']?.toString() ?? 'draft'),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'markerId': markerId,
      if (markerName != null) 'markerName': markerName,
      if (markerType != null) 'markerType': markerType,
      if (communityDescription != null)
        'communityDescription': communityDescription,
      if (scheduledFor != null) 'scheduledFor': Timestamp.fromDate(scheduledFor!),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PostDraftModel copyWith({
    String? id,
    String? markerId,
    String? markerName,
    String? markerType,
    String? communityDescription,
    DateTime? scheduledFor,
    PostDraftStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostDraftModel(
      id: id ?? this.id,
      markerId: markerId ?? this.markerId,
      markerName: markerName ?? this.markerName,
      markerType: markerType ?? this.markerType,
      communityDescription: communityDescription ?? this.communityDescription,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if the draft is ready to be published (scheduled time has passed)
  bool get isReadyToPublish =>
      status == PostDraftStatus.scheduled &&
      scheduledFor != null &&
      DateTime.now().isAfter(scheduledFor!);

  /// Check if this is just a draft (not scheduled)
  bool get isDraft => status == PostDraftStatus.draft;

  /// Check if this is scheduled for later
  bool get isScheduled => status == PostDraftStatus.scheduled;
}
