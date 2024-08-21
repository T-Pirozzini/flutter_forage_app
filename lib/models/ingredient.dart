class Ingredient {
  final String name;
  final String quantity;
  final bool isForaged;
  final String unit;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.isForaged,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'isForaged': isForaged,
      'unit': unit,
    };
  }

  static Ingredient fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'],
      quantity: map['quantity'],
      isForaged: map['isForaged'],
      unit: map['unit'],
    );
  }
}
