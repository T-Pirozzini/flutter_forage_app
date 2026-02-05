import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of an emergency notification
enum EmergencyNotificationStatus {
  active,     // Forage is planned/ongoing
  completed,  // User marked as completed/returned safely
  cancelled,  // User cancelled the forage
}

/// Represents a safety notification sent to emergency contacts.
///
/// Stored at: /Users/{userId}/EmergencyNotifications/{notificationId}
///
/// Used to notify designated emergency contacts when a user
/// plans to forage with someone new, including date, time, and location.
class EmergencyNotification {
  /// Unique notification ID (Firestore document ID)
  final String id;

  /// User ID who is going foraging
  final String userId;

  /// User email who is going foraging
  final String userEmail;

  /// Username who is going foraging
  final String username;

  /// Username of the person they're meeting
  final String partnerUsername;

  /// Planned date and time of the forage
  final DateTime plannedDateTime;

  /// General location/area description (not precise coordinates)
  final String generalLocation;

  /// List of emergency contact emails who were notified
  final List<String> notifiedEmails;

  /// When the notification was created
  final DateTime createdAt;

  /// Current status of the notification
  final EmergencyNotificationStatus status;

  /// Optional notes from the user
  final String? notes;

  /// When the user marked themselves as safe/completed
  final DateTime? completedAt;

  EmergencyNotification({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.username,
    required this.partnerUsername,
    required this.plannedDateTime,
    required this.generalLocation,
    required this.notifiedEmails,
    required this.createdAt,
    this.status = EmergencyNotificationStatus.active,
    this.notes,
    this.completedAt,
  });

  /// Create from Firestore document
  factory EmergencyNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmergencyNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      username: data['username'] ?? '',
      partnerUsername: data['partnerUsername'] ?? '',
      plannedDateTime: data['plannedDateTime'] != null
          ? (data['plannedDateTime'] as Timestamp).toDate()
          : DateTime.now(),
      generalLocation: data['generalLocation'] ?? '',
      notifiedEmails: List<String>.from(data['notifiedEmails'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: EmergencyNotificationStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => EmergencyNotificationStatus.active,
      ),
      notes: data['notes'],
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'username': username,
      'partnerUsername': partnerUsername,
      'plannedDateTime': Timestamp.fromDate(plannedDateTime),
      'generalLocation': generalLocation,
      'notifiedEmails': notifiedEmails,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      if (notes != null) 'notes': notes,
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    };
  }

  /// Create a copy with modified fields
  EmergencyNotification copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? username,
    String? partnerUsername,
    DateTime? plannedDateTime,
    String? generalLocation,
    List<String>? notifiedEmails,
    DateTime? createdAt,
    EmergencyNotificationStatus? status,
    String? notes,
    DateTime? completedAt,
  }) {
    return EmergencyNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      username: username ?? this.username,
      partnerUsername: partnerUsername ?? this.partnerUsername,
      plannedDateTime: plannedDateTime ?? this.plannedDateTime,
      generalLocation: generalLocation ?? this.generalLocation,
      notifiedEmails: notifiedEmails ?? this.notifiedEmails,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Check if the notification is active (forage is planned/ongoing)
  bool get isActive => status == EmergencyNotificationStatus.active;

  /// Check if the notification is completed
  bool get isCompleted => status == EmergencyNotificationStatus.completed;

  @override
  String toString() {
    return 'EmergencyNotification(id: $id, user: $username, partner: $partnerUsername, status: $status)';
  }
}
