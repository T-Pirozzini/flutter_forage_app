import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarkerButtons extends StatefulWidget {
  const MarkerButtons({
    Key? key,
  }) : super(key: key);

  @override
  State<MarkerButtons> createState() => _MarkerButtonsState();
}

class _MarkerButtonsState extends State<MarkerButtons> {
  final _nameTextController = TextEditingController();
  final _descriptionTextController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser?.email;

  File? _selectedImage;

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<Position> _getCurrentPosition() async {
    final location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return location;
  }

  void displayDialog(String markerType) {
    showDialog(
      context: context,
      builder: (context) => Container(
        alignment: Alignment.center,
        width: 450,
        height: 300,
        child: SingleChildScrollView(
          child: AlertDialog(
            title: const Text(
              'Add Forage Location',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Marker Type: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      markerType,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameTextController,
                  decoration: const InputDecoration(
                    hintText: 'Name your location...',
                    border: OutlineInputBorder(borderSide: BorderSide()),
                    focusColor: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: _descriptionTextController,
                    decoration: const InputDecoration(
                      hintText: 'Describe your location...',
                      border: OutlineInputBorder(borderSide: BorderSide()),
                      focusColor: Color(0xFFE65100),
                    ),
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    maxLength: 150,
                  ),
                ),
              ],
            ),
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Would you like to add an image to your location? (optional)',
                    textAlign: TextAlign.center,
                  ),
                  ElevatedButton(
                    child: const Text('+ Add Image'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text(
                            'Select Image Source',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _getImage(ImageSource.camera);
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Camera'),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _getImage(ImageSource.gallery);
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Gallery'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              // cancel button
                              Column(
                                children: [
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // cancel button
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context);
                      _nameTextController.clear();
                      _descriptionTextController.clear();
                      _selectedImage = null;
                    },
                  ),
                  // Save Forage Location
                  ElevatedButton(
                    onPressed: () async {
                      final currentPosition = await _getCurrentPosition();
                      final imageUrl = await _uploadImageToFirebaseStorage();
                      saveMarkerInfo(
                        _nameTextController.text,
                        _descriptionTextController.text,
                        markerType,
                        imageUrl,
                        currentPosition,
                        DateTime.now(),
                      );
                      Navigator.pop(context);
                      _nameTextController.clear();
                      _descriptionTextController.clear();
                      _selectedImage = null;
                    },
                    child: const Text(
                      'Save Location',
                      style: TextStyle(fontSize: 24),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadImageToFirebaseStorage() async {
    if (_selectedImage == null) return null;

    final fileName = '${DateTime.now().microsecondsSinceEpoch}.png';
    final destination = 'images/$fileName';

    final ref = firebase_storage.FirebaseStorage.instance.ref(destination);
    final task = ref.putFile(_selectedImage!);

    await task.whenComplete(() {});

    if (task.snapshot.state == firebase_storage.TaskState.success) {
      final imageUrl = await ref.getDownloadURL();
      return imageUrl;
    }

    return null;
  }

  void saveMarkerInfo(
    String markerName,
    String markerDescription,
    String markerType,
    String? markerImagePath,
    Position currentPosition,
    DateTime timestamp,
  ) async {
    if (markerImagePath != null) {
      // Upload the image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('marker_images')
          .child(DateTime.now().toString());
      final uploadTask = storageRef.putFile(File(markerImagePath));
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser)
          .collection('Markers')
          .add({
        'name': markerName,
        'description': markerDescription,
        'type': markerType,
        'image': imageUrl,
        'location': {
          'latitude': currentPosition.latitude,
          'longitude': currentPosition.longitude,
        },
        'timestamp': timestamp,
      });
    } else {
      // Save the marker details without the image URL to Firestore
      FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser)
          .collection('Markers')
          .add({
        'name': markerName,
        'description': markerDescription,
        'type': markerType,
        'location': {
          'latitude': currentPosition.latitude,
          'longitude': currentPosition.longitude,
        },
        'timestamp': timestamp,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 0,
      mini: false,
      childrenButtonSize: const Size(70, 70),
      spaceBetweenChildren: 3,
      foregroundColor: Colors.white,
      backgroundColor: Colors.grey.shade800,
      activeForegroundColor: Colors.black,
      activeBackgroundColor: Colors.deepOrange.shade300,
      elevation: 8.0,
      animationCurve: Curves.elasticInOut,
      isOpenOnStart: false,
      shape: const RoundedRectangleBorder(),
      children: [
        SpeedDialChild(
          child: Image.asset('lib/assets/images/plant.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => displayDialog('Plant'),
        ),
        SpeedDialChild(
          child: Image.asset('lib/assets/images/berries.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => displayDialog('Berries'),
        ),
        SpeedDialChild(
          child: Image.asset('lib/assets/images/mushroom.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => displayDialog('Mushroom'),
        ),
        SpeedDialChild(
          child: Image.asset('lib/assets/images/tree.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => displayDialog('Tree'),
        ),
        SpeedDialChild(
          child: Image.asset('lib/assets/images/fish.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => displayDialog('Fish'),
        ),
      ],
    );
  }
}
