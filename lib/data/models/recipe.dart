import 'package:flutter_forager_app/data/models/ingredient.dart';

class Recipe {
  final String id;
  final String name;
  final String? description;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final List<String> imageUrls;
  final DateTime timestamp;
  final String userEmail;
  final String userName;
  final List<String> likes; // Deprecated: kept for backward compatibility
  final int likeCount;
  final int saveCount;
  final int commentCount;

  Recipe({
    required this.id,
    required this.name,
    this.description,
    required this.ingredients,
    required this.steps,
    required this.imageUrls,
    required this.timestamp,
    required this.userEmail,
    required this.userName,
    this.likes = const [],
    this.likeCount = 0,
    this.saveCount = 0,
    this.commentCount = 0,
  });

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    List<Ingredient>? ingredients,
    List<String>? steps,
    List<String>? imageUrls,
    DateTime? timestamp,
    String? userEmail,
    String? userName,
    List<String>? likes,
    int? likeCount,
    int? saveCount,
    int? commentCount,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      imageUrls: imageUrls ?? this.imageUrls,
      timestamp: timestamp ?? this.timestamp,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      likes: likes ?? this.likes,
      likeCount: likeCount ?? this.likeCount,
      saveCount: saveCount ?? this.saveCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  /// Get the count of foraged ingredients
  int get foragedIngredientCount =>
      ingredients.where((i) => i.isForaged).length;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ingredients':
          ingredients.map((ingredient) => ingredient.toMap()).toList(),
      'steps': steps,
      'imageUrls': imageUrls,
      'timestamp': timestamp.toIso8601String(),
      'userEmail': userEmail,
      'userName': userName,
      'likes': likes,
      'likeCount': likeCount,
      'saveCount': saveCount,
      'commentCount': commentCount,
    };
  }

  static Recipe fromMap(String id, Map<String, dynamic> map) {
    // For backward compatibility, use likes array length if likeCount not set
    final likesArray = map['likes'] != null
        ? List<String>.from(map['likes'] as List<dynamic>)
        : <String>[];

    return Recipe(
      id: id,
      name: map['name'] as String,
      description: map['description'] as String?,
      ingredients: (map['ingredients'] as List<dynamic>)
          .map((ingredientMap) =>
              Ingredient.fromMap(ingredientMap as Map<String, dynamic>))
          .toList(),
      steps: List<String>.from(map['steps'] as List<dynamic>),
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(map['imageUrls'] as List<dynamic>)
          : [],
      timestamp: DateTime.parse(map['timestamp'] as String),
      userEmail: map['userEmail'] as String,
      userName: map['userName'] as String,
      likes: likesArray,
      likeCount: (map['likeCount'] as int?) ?? likesArray.length,
      saveCount: (map['saveCount'] as int?) ?? 0,
      commentCount: (map['commentCount'] as int?) ?? 0,
    );
  }
}
