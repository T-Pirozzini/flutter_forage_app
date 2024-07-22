class Recipe {
  final String name;
  final List<String> ingredients;
  final List<String> steps;
  final List<String> imageUrls;
  final DateTime timestamp;
  final String userId;

  Recipe({
    required this.name,
    required this.ingredients,
    required this.steps,
    required this.imageUrls,
    required this.timestamp,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ingredients': ingredients,
      'steps': steps,
      'imagePaths': imageUrls,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }
}