import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/models/recipe.dart';
import 'package:flutter_forager_app/providers/recipe_provider.dart';
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
  final List<String> _ingredients = [];
  final List<String> _steps = [];
  final String _userEmail = FirebaseAuth.instance.currentUser!.email!;
  String? _username;

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
    final ingredient = _ingredientController.text.trim();
    final quantity = _quantityController.text.trim();
    if (ingredient.isNotEmpty && quantity.isNotEmpty) {
      setState(() {
        _ingredients.add('$quantity $ingredient');
        _ingredientController.clear();
        _quantityController.clear();
      });
    }
  }

  Future<void> _submitRecipe(WidgetRef ref) async {
    final imageUrls = await Future.wait(
      _images.map((image) => _uploadImageToFirebaseStorage(image)),
    );

    final recipe = Recipe(
      name: _nameController.text.trim(),
      ingredients: _ingredients,
      steps: _steps,
      imageUrls: imageUrls,
      timestamp: DateTime.now(),
      userEmail: _userEmail,
      userName: _username!,
    );

    await ref.read(recipeProvider).addRecipe(recipe);

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
                    child: TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: 'Quantity'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ingredientController,
                      decoration: InputDecoration(labelText: 'Ingredient'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addIngredient,
                  ),
                ],
              ),
              Wrap(
                children: _ingredients.map((ingredient) {
                  return Chip(
                    label: Text(ingredient),
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
