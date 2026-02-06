import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a roadmap item
enum RoadmapStatus {
  completed,
  inProgress,
  planned;

  String get displayName {
    switch (this) {
      case RoadmapStatus.completed:
        return 'Completed';
      case RoadmapStatus.inProgress:
        return 'In Progress';
      case RoadmapStatus.planned:
        return 'Planned';
    }
  }

  String get icon {
    switch (this) {
      case RoadmapStatus.completed:
        return 'check_circle';
      case RoadmapStatus.inProgress:
        return 'pending';
      case RoadmapStatus.planned:
        return 'schedule';
    }
  }

  static RoadmapStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'completed':
        return RoadmapStatus.completed;
      case 'inprogress':
      case 'in_progress':
        return RoadmapStatus.inProgress;
      case 'planned':
      default:
        return RoadmapStatus.planned;
    }
  }
}

/// Model for roadmap/changelog items
class RoadmapItemModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final RoadmapStatus status;
  final String? version;

  const RoadmapItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    this.version,
  });

  factory RoadmapItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RoadmapItemModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      status: RoadmapStatus.fromString(data['status']?.toString() ?? 'planned'),
      version: data['version']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'status': status.name,
      if (version != null) 'version': version,
    };
  }

  RoadmapItemModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    RoadmapStatus? status,
    String? version,
  }) {
    return RoadmapItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      status: status ?? this.status,
      version: version ?? this.version,
    );
  }

  /// Check if item is completed
  bool get isCompleted => status == RoadmapStatus.completed;

  /// Check if item is in progress
  bool get isInProgress => status == RoadmapStatus.inProgress;

  /// Check if item is planned
  bool get isPlanned => status == RoadmapStatus.planned;
}
