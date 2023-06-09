import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MarkerButtons extends StatefulWidget {
  const MarkerButtons({
    super.key,
  });

  @override
  State<MarkerButtons> createState() => _MarkerButtonsState();
}

class _MarkerButtonsState extends State<MarkerButtons> {
  // text controller
  final _nameTextController = TextEditingController();
  final _descriptionTextController = TextEditingController();

  // get current user
  final currentUser = FirebaseAuth.instance.currentUser?.email;

  // image picker
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

  // get current position
  Future<Position> _getCurrentPosition() async {
    final location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return location;
  }

  void displayDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Forage Location'),
        content: Column(
          children: [
            TextField(
              controller: _nameTextController,
              decoration: const InputDecoration(
                hintText: 'Name your location...',
              ),
            ),
            TextField(
              controller: _descriptionTextController,
              decoration: const InputDecoration(
                hintText: 'Describe your location...',
              ),
            ),
          ],
        ),
        actions: [
          // cancel button
          Column(
            children: [
              // if (_selectedImage != null)
              // Image.file(_selectedImage!),
              ElevatedButton(
                child: Text('im a child'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Select Image Source'),
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _getImage(ImageSource.camera);
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.camera),
                            label: Text('Camera'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              _getImage(ImageSource.gallery);
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.photo_library),
                            label: Text('Gallery'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                  _nameTextController.clear();
                  _descriptionTextController.clear();
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  final currentPosition = await _getCurrentPosition();
                  saveMarkerInfo(
                    _nameTextController.text,
                    _descriptionTextController.text,
                    'Fern',
                    _selectedImage?.path,
                    currentPosition,
                    10,
                  );
                },
                child: const Text('Save Marker'),
              )
            ],
          ),

          // // save button
          // TextButton(
          //   child: const Text('Post'),
          //   onPressed: () {
          //     addComment(_commentTextController.text);
          //     Navigator.pop(context);
          //     _commentTextController.clear();
          //   },
          // ),
        ],
      ),
    );
  }

  void saveMarkerInfo(
      String markerName,
      String markerDescription,
      String markerType,
      String? markerImagePath,
      Position currentPosition,
      int timestamp) {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser)
        .collection('Markers')
        .add({
      'name': markerName,
      'description': markerDescription,
      'type': markerType,
      'image': markerImagePath,
      'location': {
        'latitude': currentPosition.latitude,
        'longitude': currentPosition.longitude,
      },
      'timestamp': timestamp,
    });
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
          child: Image.asset('lib/assets/images/fern.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: displayDialog,
        ),
        SpeedDialChild(
            child: Image.asset('lib/assets/images/berries.png', width: 40),
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.white,
            onTap: displayDialog),
        SpeedDialChild(
          child: Image.asset('lib/assets/images/mushroom.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => {},
        ),
        SpeedDialChild(
          child: Image.asset('lib/assets/images/tree.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => {},
        ),
        SpeedDialChild(
          child: Image.asset('lib/assets/images/fish.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => {},
        ),
      ],
    );
  }
}
