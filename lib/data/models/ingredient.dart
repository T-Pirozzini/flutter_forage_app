class Ingredient {
  final String name;
  final String quantity;
  final bool isForaged;

  // Optional forage type for categorization (mushroom, berries, herbs, etc.)
  final String? forageType;

  // Prep notes for wild ingredients (e.g., "Soak overnight", "Remove gills")
  final String? prepNotes;

  // Store-bought substitution (e.g., "Cremini mushrooms")
  final String? substitution;

  // Friends-only location link
  final String? linkedMarkerId;
  final String? linkedMarkerName;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.isForaged,
    this.forageType,
    this.prepNotes,
    this.substitution,
    this.linkedMarkerId,
    this.linkedMarkerName,
  });

  // Computed property
  bool get hasLinkedLocation => linkedMarkerId != null;

  Ingredient copyWith({
    String? name,
    String? quantity,
    bool? isForaged,
    String? forageType,
    String? prepNotes,
    String? substitution,
    String? linkedMarkerId,
    String? linkedMarkerName,
  }) {
    return Ingredient(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isForaged: isForaged ?? this.isForaged,
      forageType: forageType ?? this.forageType,
      prepNotes: prepNotes ?? this.prepNotes,
      substitution: substitution ?? this.substitution,
      linkedMarkerId: linkedMarkerId ?? this.linkedMarkerId,
      linkedMarkerName: linkedMarkerName ?? this.linkedMarkerName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'isForaged': isForaged,
      if (forageType != null) 'forageType': forageType,
      if (prepNotes != null) 'prepNotes': prepNotes,
      if (substitution != null) 'substitution': substitution,
      if (linkedMarkerId != null) 'linkedMarkerId': linkedMarkerId,
      if (linkedMarkerName != null) 'linkedMarkerName': linkedMarkerName,
    };
  }

  static Ingredient fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? '',
      isForaged: map['isForaged'] ?? false,
      forageType: map['forageType'],
      prepNotes: map['prepNotes'],
      substitution: map['substitution'],
      linkedMarkerId: map['linkedMarkerId'],
      linkedMarkerName: map['linkedMarkerName'],
    );
  }
}
