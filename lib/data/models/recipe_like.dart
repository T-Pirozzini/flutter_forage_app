import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a like on a recipe, stored in the recipe's Likes subcollection.
///
/// Stored at: /Recipes/{recipeId}/Likes/{userEmail}
class RecipeLikeModel {
  /// User's email (also serves as document ID)
  final String userEmail;

  /// When the like was created
  final DateTime createdAt;

  RecipeLikeModel({
    required this.userEmail,
    required this.createdAt,
  });

  /// Create from Firestore document
  factory RecipeLikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecipeLikeModel(
      userEmail: data['userEmail'] ?? doc.id,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Create from map
  factory RecipeLikeModel.fromMap(Map<String, dynamic> map) {
    return RecipeLikeModel(
      userEmail: map['userEmail'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userEmail': userEmail,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeLikeModel &&
          runtimeType == other.runtimeType &&
          userEmail == other.userEmail;

  @override
  int get hashCode => userEmail.hashCode;

  @override
  String toString() {
    return 'RecipeLikeModel(userEmail: $userEmail, createdAt: $createdAt)';
  }
}
