import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/models/ingredient.dart';
import 'package:flutter_forager_app/models/recipe.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class AddRecipePage extends StatefulWidget {
  @override
  _AddRecipePageState createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _stepController = TextEditingController();
  final List<Ingredient> _ingredients = [];
  final List<String> _steps = [];
  final String _userEmail = FirebaseAuth.instance.currentUser!.email!;
  String? _username;
  bool _isForaged = false;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_userEmail)
          .get();
      if (userDoc.exists) {
        setState(() {
          _username = userDoc.get('username');
        });
      }
    } catch (e) {
      // Handle errors if needed
      print('Error fetching username: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can only add up to 3 photos.')),
      );
      return;
    }

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  Future<String> _uploadImageToFirebaseStorage(File image) async {
    final compressedImage = await FlutterImageCompress.compressWithFile(
      image.path,
      quality: 70,
    );

    final fileName = '${DateTime.now().microsecondsSinceEpoch}.png';
    final destination = 'recipes/$fileName';

    final ref = firebase_storage.FirebaseStorage.instance.ref(destination);
    final metadata = firebase_storage.SettableMetadata(
      contentType: 'image/png',
    );

    await ref.putData(compressedImage!, metadata);
    final imageUrl = await ref.getDownloadURL();
    return imageUrl;
  }

  void _addIngredient() {
    final ingredientName = _ingredientController.text.trim();
    final quantity = _quantityController.text.trim();
    if (ingredientName.isNotEmpty && quantity.isNotEmpty) {
      final ingredient = Ingredient(
        name: ingredientName,
        quantity: quantity,
        isForaged: _isForaged,
      );
      setState(() {
        _ingredients.add(ingredient);
        _ingredientController.clear();
        _quantityController.clear();
        _isForaged = false; // Reset for next input
      });
    }
  }

  Future<void> _submitRecipe(WidgetRef ref) async {
    final imageUrls = await Future.wait(
      _images.map((image) => _uploadImageToFirebaseStorage(image)),
    );

    final recipesCollection = FirebaseFirestore.instance.collection('Recipes');
    final docRef =
        recipesCollection.doc(); // Generate a document reference with a new ID

    final recipe = Recipe(
      id: docRef.id, // Use the generated ID
      name: _nameController.text.trim(),
      ingredients: _ingredients, // This is already a list of Ingredient objects
      steps: _steps,
      imageUrls: imageUrls,
      timestamp: DateTime.now(),
      userEmail: _userEmail,
      userName: _username!,
    );

    // Save the recipe to Firestore using the generated document reference
    await docRef.set(recipe.toMap());

    // Clear fields after submission
    setState(() {
      _nameController.clear();
      _ingredientController.clear();
      _quantityController.clear();
      _stepController.clear();
      _images.clear();
      _ingredients.clear();
      _steps.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recipe submitted successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Recipe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Recipe Name'),
              ),
              SizedBox(height: 10),
              Text('Photos:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                children: [
                  for (var image in _images)
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.file(image,
                          width: 80, height: 80, fit: BoxFit.cover),
                    ),
                  if (_images.length < 3)
                    IconButton(
                      icon: Icon(Icons.add_a_photo),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                ],
              ),
              SizedBox(height: 20),
              Text('Ingredients:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: 'Quantity'),                 
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _ingredientController,
                      decoration: InputDecoration(labelText: 'Ingredient'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    children: [
                      Text('Foraged?'),
                      Checkbox(
                        value: _isForaged,
                        onChanged: (bool? value) {
                          setState(() {
                            _isForaged = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addIngredient,
                  ),
                ],
              ),
              Wrap(
                children: _ingredients.map((ingredient) {
                  final source = ingredient.isForaged ? 'Foraged' : 'Bought';
                  return Chip(
                    label: Text(
                        '${ingredient.quantity} ${ingredient.name} ($source)'),
                    onDeleted: () {
                      setState(() {
                        _ingredients.remove(ingredient);
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Text('Instructions:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stepController,
                      decoration: InputDecoration(labelText: 'Enter step'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      final step = _stepController.text.trim();
                      if (step.isNotEmpty) {
                        setState(() {
                          _steps.add(step);
                          _stepController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _steps.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final step = entry.value;
                  return Row(
                    children: [
                      Text('Step $index: $step'),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _steps.remove(step);
                          });
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
              Center(
                child: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () => _submitRecipe(ref),
                      child: Text('Submit Recipe'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
