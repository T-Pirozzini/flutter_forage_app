import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a saved/bookmarked recipe stored in the user's SavedRecipes subcollection.
///
/// Stored at: /Users/{userId}/SavedRecipes/{savedRecipeId}
/// Denormalizes recipe data for efficient display without additional lookups.
class SavedRecipeModel {
  /// Unique saved recipe ID
  final String id;

  /// ID of the original recipe
  final String recipeId;

  /// Name of the recipe (denormalized)
  final String recipeName;

  /// Email of the recipe's owner
  final String recipeOwner;

  /// Username of the recipe's owner (denormalized)
  final String recipeOwnerName;

  /// Primary image URL (denormalized for display)
  final String? primaryImageUrl;

  /// Number of foraged ingredients (denormalized)
  final int foragedIngredientCount;

  /// When the recipe was saved
  final DateTime savedAt;

  /// Optional user notes about this saved recipe
  final String? notes;

  SavedRecipeModel({
    required this.id,
    required this.recipeId,
    required this.recipeName,
    required this.recipeOwner,
    required this.recipeOwnerName,
    this.primaryImageUrl,
    this.foragedIngredientCount = 0,
    required this.savedAt,
    this.notes,
  });

  /// Create from Firestore document
  factory SavedRecipeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedRecipeModel(
      id: doc.id,
      recipeId: data['recipeId'] ?? '',
      recipeName: data['recipeName'] ?? '',
      recipeOwner: data['recipeOwner'] ?? '',
      recipeOwnerName: data['recipeOwnerName'] ?? '',
      primaryImageUrl: data['primaryImageUrl'],
      foragedIngredientCount: (data['foragedIngredientCount'] as int?) ?? 0,
      savedAt: data['savedAt'] != null
          ? (data['savedAt'] as Timestamp).toDate()
          : DateTime.now(),
      notes: data['notes'],
    );
  }

  /// Create from map
  factory SavedRecipeModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return SavedRecipeModel(
      id: id ?? map['id'] ?? '',
      recipeId: map['recipeId'] ?? '',
      recipeName: map['recipeName'] ?? '',
      recipeOwner: map['recipeOwner'] ?? '',
      recipeOwnerName: map['recipeOwnerName'] ?? '',
      primaryImageUrl: map['primaryImageUrl'],
      foragedIngredientCount: (map['foragedIngredientCount'] as int?) ?? 0,
      savedAt: map['savedAt'] != null
          ? (map['savedAt'] as Timestamp).toDate()
          : DateTime.now(),
      notes: map['notes'],
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'recipeId': recipeId,
      'recipeName': recipeName,
      'recipeOwner': recipeOwner,
      'recipeOwnerName': recipeOwnerName,
      if (primaryImageUrl != null) 'primaryImageUrl': primaryImageUrl,
      'foragedIngredientCount': foragedIngredientCount,
      'savedAt': Timestamp.fromDate(savedAt),
      if (notes != null) 'notes': notes,
    };
  }

  /// Create a copy with modified fields
  SavedRecipeModel copyWith({
    String? id,
    String? recipeId,
    String? recipeName,
    String? recipeOwner,
    String? recipeOwnerName,
    String? primaryImageUrl,
    int? foragedIngredientCount,
    DateTime? savedAt,
    String? notes,
  }) {
    return SavedRecipeModel(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      recipeOwner: recipeOwner ?? this.recipeOwner,
      recipeOwnerName: recipeOwnerName ?? this.recipeOwnerName,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      foragedIngredientCount:
          foragedIngredientCount ?? this.foragedIngredientCount,
      savedAt: savedAt ?? this.savedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedRecipeModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SavedRecipeModel(id: $id, recipeId: $recipeId, recipeName: $recipeName)';
  }
}
