import 'package:flutter_forager_app/models/ingredient.dart';

class Recipe {
  final String id;
  final String name;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final List<String> imageUrls;
  final DateTime timestamp;
  final String userEmail;
  final String userName;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.steps,
    required this.imageUrls,
    required this.timestamp,
    required this.userEmail,
    required this.userName,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ingredients': ingredients.map((ingredient) => ingredient.toMap()).toList(),
      'steps': steps,
      'imageUrls': imageUrls,
      'timestamp': timestamp.toIso8601String(),
      'userEmail': userEmail,
      'userName': userName,
    };
  }

  static Recipe fromMap(String id, Map<String, dynamic> map) {
    return Recipe(
      id: id,
      name: map['name'],
      ingredients: (map['ingredients'] as List)
          .map((ingredientMap) => Ingredient.fromMap(ingredientMap))
          .toList(),
      steps: List<String>.from(map['steps']),
      imageUrls:
          map['imageUrls'] != null ? List<String>.from(map['imageUrls']) : [],
      timestamp: DateTime.parse(map['timestamp']),
      userEmail: map['userEmail'],
      userName: map['userName'],
    );
  }
}
