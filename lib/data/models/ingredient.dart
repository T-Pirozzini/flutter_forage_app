class Ingredient {
  final String name;
  final String quantity;
  final bool isForaged;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.isForaged,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'isForaged': isForaged,
    };
  }

  static Ingredient fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'],
      quantity: map['quantity'],
      isForaged: map['isForaged'],
    );
  }
}
