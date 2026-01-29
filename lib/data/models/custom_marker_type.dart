import 'package:cloud_firestore/cloud_firestore.dart';

/// Custom marker type defined by user with an emoji icon
class CustomMarkerType {
  final String id;
  final String name;
  final String emoji;
  final String userId;
  final DateTime createdAt;

  CustomMarkerType({
    required this.id,
    required this.name,
    required this.emoji,
    required this.userId,
    required this.createdAt,
  });

  factory CustomMarkerType.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomMarkerType(
      id: doc.id,
      name: data['name'] ?? '',
      emoji: data['emoji'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'emoji': emoji,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Type identifier used in markers (prefixed to distinguish from built-in types)
  String get typeId => 'custom_${id}_$emoji';

  /// Check if a type string represents a custom type
  static bool isCustomType(String type) => type.startsWith('custom_');

  /// Extract emoji from a custom type string
  static String? getEmojiFromType(String type) {
    if (!isCustomType(type)) return null;
    final parts = type.split('_');
    return parts.length >= 3 ? parts.last : null;
  }
}
