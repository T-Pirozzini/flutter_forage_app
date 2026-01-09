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
  final List<String> likes;

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
  });

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
    };
  }

  static Recipe fromMap(String id, Map<String, dynamic> map) {
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
      likes: map['likes'] != null
          ? List<String>.from(map['likes'] as List<dynamic>)
          : [],
    );
  }
}
