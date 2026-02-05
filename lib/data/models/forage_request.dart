import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a forage request
enum ForageRequestStatus {
  pending,   // Waiting for recipient response
  accepted,  // Recipient accepted
  declined,  // Recipient declined
  expired,   // Request expired (no response after X days)
}

/// Represents a "Let's Forage Together" request between two users.
///
/// Stored at: /ForageRequests/{requestId}
///
/// Flow:
/// 1. User A sends request with short message to User B
/// 2. User B accepts or declines (with optional response message)
/// 3. If accepted, both users share contact info for off-platform communication
class ForageRequest {
  /// Unique request ID (Firestore document ID)
  final String id;

  /// Sender's email
  final String fromEmail;

  /// Sender's username (denormalized)
  final String fromUsername;

  /// Recipient's email
  final String toEmail;

  /// Recipient's username (denormalized)
  final String toUsername;

  /// Short intro message from sender (150 char max)
  final String message;

  /// Optional response message from recipient
  final String? responseMessage;

  /// Current status of the request
  final ForageRequestStatus status;

  /// When the request was sent
  final DateTime createdAt;

  /// When the recipient responded (accepted/declined)
  final DateTime? respondedAt;

  // Contact exchange fields - populated after mutual acceptance

  /// Sender's preferred contact method ('facebook', 'discord', 'email', 'phone', etc.)
  final String? fromContactMethod;

  /// Sender's contact info (handle, email, phone number)
  final String? fromContactInfo;

  /// Recipient's preferred contact method
  final String? toContactMethod;

  /// Recipient's contact info
  final String? toContactInfo;

  ForageRequest({
    required this.id,
    required this.fromEmail,
    required this.fromUsername,
    required this.toEmail,
    required this.toUsername,
    required this.message,
    this.responseMessage,
    this.status = ForageRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
    this.fromContactMethod,
    this.fromContactInfo,
    this.toContactMethod,
    this.toContactInfo,
  });

  /// Create from Firestore document
  factory ForageRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ForageRequest(
      id: doc.id,
      fromEmail: data['fromEmail'] ?? '',
      fromUsername: data['fromUsername'] ?? '',
      toEmail: data['toEmail'] ?? '',
      toUsername: data['toUsername'] ?? '',
      message: data['message'] ?? '',
      responseMessage: data['responseMessage'],
      status: ForageRequestStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ForageRequestStatus.pending,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      fromContactMethod: data['fromContactMethod'],
      fromContactInfo: data['fromContactInfo'],
      toContactMethod: data['toContactMethod'],
      toContactInfo: data['toContactInfo'],
    );
  }

  /// Create from map (for batch operations)
  factory ForageRequest.fromMap(String id, Map<String, dynamic> map) {
    return ForageRequest(
      id: id,
      fromEmail: map['fromEmail'] ?? '',
      fromUsername: map['fromUsername'] ?? '',
      toEmail: map['toEmail'] ?? '',
      toUsername: map['toUsername'] ?? '',
      message: map['message'] ?? '',
      responseMessage: map['responseMessage'],
      status: ForageRequestStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ForageRequestStatus.pending,
      ),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] as Timestamp).toDate()
          : null,
      fromContactMethod: map['fromContactMethod'],
      fromContactInfo: map['fromContactInfo'],
      toContactMethod: map['toContactMethod'],
      toContactInfo: map['toContactInfo'],
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'fromEmail': fromEmail,
      'fromUsername': fromUsername,
      'toEmail': toEmail,
      'toUsername': toUsername,
      'message': message,
      if (responseMessage != null) 'responseMessage': responseMessage,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      if (respondedAt != null) 'respondedAt': Timestamp.fromDate(respondedAt!),
      if (fromContactMethod != null) 'fromContactMethod': fromContactMethod,
      if (fromContactInfo != null) 'fromContactInfo': fromContactInfo,
      if (toContactMethod != null) 'toContactMethod': toContactMethod,
      if (toContactInfo != null) 'toContactInfo': toContactInfo,
    };
  }

  /// Create a copy with modified fields
  ForageRequest copyWith({
    String? id,
    String? fromEmail,
    String? fromUsername,
    String? toEmail,
    String? toUsername,
    String? message,
    String? responseMessage,
    ForageRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? fromContactMethod,
    String? fromContactInfo,
    String? toContactMethod,
    String? toContactInfo,
  }) {
    return ForageRequest(
      id: id ?? this.id,
      fromEmail: fromEmail ?? this.fromEmail,
      fromUsername: fromUsername ?? this.fromUsername,
      toEmail: toEmail ?? this.toEmail,
      toUsername: toUsername ?? this.toUsername,
      message: message ?? this.message,
      responseMessage: responseMessage ?? this.responseMessage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      fromContactMethod: fromContactMethod ?? this.fromContactMethod,
      fromContactInfo: fromContactInfo ?? this.fromContactInfo,
      toContactMethod: toContactMethod ?? this.toContactMethod,
      toContactInfo: toContactInfo ?? this.toContactInfo,
    );
  }

  /// Check if the request is pending
  bool get isPending => status == ForageRequestStatus.pending;

  /// Check if the request was accepted
  bool get isAccepted => status == ForageRequestStatus.accepted;

  /// Check if the request was declined
  bool get isDeclined => status == ForageRequestStatus.declined;

  /// Check if contact info has been exchanged
  bool get hasContactExchange =>
      fromContactInfo != null && toContactInfo != null;

  /// Check if this request involves a specific user (as sender or recipient)
  bool involvesUser(String email) => fromEmail == email || toEmail == email;

  /// Get the other user's email given one user's email
  String getOtherUserEmail(String myEmail) =>
      fromEmail == myEmail ? toEmail : fromEmail;

  /// Get the other user's username given one user's email
  String getOtherUsername(String myEmail) =>
      fromEmail == myEmail ? toUsername : fromUsername;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForageRequest &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ForageRequest(id: $id, from: $fromUsername, to: $toUsername, status: $status)';
  }
}
