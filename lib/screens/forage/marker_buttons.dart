import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Add Forage Location',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Marker Type: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(markerType),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameTextController,
                    decoration: const InputDecoration(
                      hintText: 'Name your location...',
                      border: OutlineInputBorder(borderSide: BorderSide()),
                      focusColor: Color(0xFFE65100),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name for the location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: _descriptionTextController,
                      decoration: const InputDecoration(
                        hintText: 'Describe your location...',
                        border: OutlineInputBorder(borderSide: BorderSide()),
                        focusColor: Color(0xFFE65100),
                      ),
                      textInputAction: TextInputAction.newline,
                      maxLines: null,
                      maxLength: 150,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please provide a description';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_selectedImage != null)
                    Center(
                      child: Image.file(
                        _selectedImage!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: ElevatedButton(
                    child: const Text('+ Add Image'),
                    onPressed: _selectedImage == null
                        ? () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text(
                                  'Select Image Source',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await _getImage(ImageSource.camera);
                                            setState(() {});
                                            Navigator.pop(context);
                                          },
                                          icon: const Icon(Icons.camera_alt),
                                          label: const Text('Camera'),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await _getImage(
                                                ImageSource.gallery);
                                            setState(() {});
                                            Navigator.pop(context);
                                          },
                                          icon: const Icon(Icons.photo_library),
                                          label: const Text('Gallery'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
                _selectedImage == null
                    ? Column(
                        children: [
                          const Text(
                            'Add an image to your location? (optional)',
                            textAlign: TextAlign.center,
                          ),
                          const Text(
                            'In poor service areas: Take a picture with your camera app and add the image later.',
                            style: TextStyle(
                                fontSize: 12, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : const SizedBox(),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                    _nameTextController.clear();
                    _descriptionTextController.clear();
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate the form before saving
                    if (_formKey.currentState?.validate() ?? false) {
                      // Form is valid, proceed with saving
                      _saveLocation(markerType);
                      Navigator.pop(context);
                    }
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
    );
  }

  void _saveLocation(String markerType) async {
    final currentPosition = await _getCurrentPosition();
    final imageUrl = await _uploadImageToFirebaseStorage();
    saveMarkerInfo(
      _nameTextController.text,
      _descriptionTextController.text,
      markerType,
      imageUrl,
      currentPosition,
      DateTime.now(),
      currentUser,
    );
    _nameTextController.clear();
    _descriptionTextController.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  Future<String?> _uploadImageToFirebaseStorage() async {
    if (_selectedImage == null) return null;

    final compressedImage = await FlutterImageCompress.compressWithFile(
      _selectedImage!.path,
      quality: 70, // Adjust the quality as desired (0-100)
    );

    final fileName = '${DateTime.now().microsecondsSinceEpoch}.png';
    final destination = 'images/$fileName';

    final ref = firebase_storage.FirebaseStorage.instance.ref(destination);
    final metadata = firebase_storage.SettableMetadata(
      contentType: 'image/png',
    );

    try {
      await ref.putData(compressedImage!, metadata);
      final imageUrl = await ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  void saveMarkerInfo(
    String markerName,
    String markerDescription,
    String markerType,
    String? markerImageUrl,
    Position currentPosition,
    DateTime timestamp,
    String? currentUser,
  ) async {
    // UPDATED: Query root Markers collection
    final userMarkersRef = FirebaseFirestore.instance
        .collection('Markers')
        .where('markerOwner', isEqualTo: currentUser);
    final markerQuerySnapshot = await userMarkersRef.get();
    final markerCount = markerQuerySnapshot.size;
    print(markerCount);

    if (markerCount <= 10) {
      if (markerImageUrl != null) {
        // UPDATED: Save to root Markers collection
        FirebaseFirestore.instance
            .collection('Markers')
            .add({
          'name': markerName,
          'description': markerDescription,
          'type': markerType,
          'image': markerImageUrl,
          'location': {
            'latitude': currentPosition.latitude,
            'longitude': currentPosition.longitude,
          },
          'timestamp': timestamp,
          'markerOwner': currentUser,
          'userId': currentUser, // Added for consistency
        });
      } else {
        // UPDATED: Save to root Markers collection
        FirebaseFirestore.instance
            .collection('Markers')
            .add({
          'name': markerName,
          'description': markerDescription,
          'type': markerType,
          'image':
              'https://st2.depositphotos.com/2586633/46477/v/600/depositphotos_464771766-stock-illustration-no-photo-or-blank-image.jpg',
          'location': {
            'latitude': currentPosition.latitude,
            'longitude': currentPosition.longitude,
          },
          'timestamp': timestamp,
          'userId': currentUser, // Added for consistency
          'markerOwner': currentUser,
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marker limit reached. You cannot save more markers.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50.0,
        left: 10.0,
        right: 10.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Text(
              'Select a marker for your forage location.',
              style: TextStyle(color: Colors.white, fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay?.insert(overlayEntry);

    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
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
      onOpen: () => _showOverlay(context),
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
        SpeedDialChild(
          child: Image.asset('lib/assets/images/shellfish.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => displayDialog('Shellfish'),
        ),
        SpeedDialChild(
          child: Image.asset('lib/assets/images/nuts.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => displayDialog('Nuts'),
        ),
      ],
    );
  }
}
