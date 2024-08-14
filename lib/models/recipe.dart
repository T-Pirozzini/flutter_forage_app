class Recipe {
  final String id;
  final String name;
  final List<String> ingredients;
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
      'ingredients': ingredients,
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
      ingredients: List<String>.from(map['ingredients']),
      steps: List<String>.from(map['steps']),
      imageUrls:
          map['imageUrls'] != null ? List<String>.from(map['imageUrls']) : [],
      timestamp: DateTime.parse(map['timestamp']),
      userEmail: map['userEmail'],
      userName: map['userName'],
    );
  }
}
