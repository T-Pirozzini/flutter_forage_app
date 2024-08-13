import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../home/home_page.dart';

class ForageLocationInfo extends StatefulWidget {
  final String name;
  final String description;
  final String imageUrl;
  final double lat;
  final double lng;
  final String timestamp;
  final String type;
  final String markerOwner;

  const ForageLocationInfo(
      {super.key,
      required this.name,
      required this.description,
      required this.lat,
      required this.lng,
      required this.imageUrl,
      required this.timestamp,
      required this.type,
      required this.markerOwner});

  @override
  State<ForageLocationInfo> createState() => _ForageLocationInfoState();
}

class _ForageLocationInfoState extends State<ForageLocationInfo> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  // current user
  final currentUser = FirebaseAuth.instance.currentUser!;
  final picker = ImagePicker();
  late String imageUrl;

  @override
  void initState() {
    imageUrl = widget.imageUrl;
    super.initState();
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      await uploadImage(image);
    }
  }

  Future<void> uploadImage(File image) async {
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: 70, // Adjust the quality as desired (0-100)
      );

      final fileName = '${DateTime.now().microsecondsSinceEpoch}.png';
      final storageRef =
          FirebaseStorage.instance.ref().child('images/$fileName');
      final uploadTask = storageRef.putData(compressedImage!);

      final snapshot = await uploadTask.whenComplete(() {});
      final newImageUrl = await snapshot.ref.getDownloadURL();

      await updateImageUrlInFirestore(newImageUrl);

      setState(() {
        imageUrl = newImageUrl;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
        ),
      );
    }
  }

  Future<void> updateImageUrlInFirestore(String newImageUrl) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.markerOwner)
        .collection('Markers')
        .where('name', isEqualTo: widget.name)
        .where('description', isEqualTo: widget.description)
        .where('type', isEqualTo: widget.type)
        .get()
        .then((snapshot) {
      for (DocumentSnapshot ds in snapshot.docs) {
        ds.reference.update({'image': newImageUrl});
      }
    });
  }

  void postToCommunity() async {
    final postsCollection = FirebaseFirestore.instance.collection('Posts');

    try {
      // Create a new post document
      final newPost = await postsCollection.add({
        'name': widget.name,
        'description': widget.description,
        'timestamp': widget.timestamp,
        'latitude': widget.lat,
        'longitude': widget.lng,
        'type': widget.type,
        'imageUrl': widget.imageUrl,
        'user': currentUser.email,
        'likeCount': 0,
        'likedBy': [],
        'bookmarkCount': 0,
        'bookmarkedBy': [],
        'commentCount': 0,
        'postTimestamp': DateTime.now().toString(),
        'markerOwner': widget.markerOwner,
      });

      if (newPost.id.isNotEmpty) {
        final snackBar = SnackBar(
          content: Text('New post added with ID: ${newPost.id}'),
          duration: const Duration(seconds: 2),
        );
        _scaffoldKey.currentState?.showSnackBar(snackBar);
        // Success! You can perform any additional actions here.
      } else {
        const snackBar = SnackBar(
          content: Text('Failed to add new post.'),
          duration: Duration(seconds: 2),
        );
        _scaffoldKey.currentState?.showSnackBar(snackBar);
        // Handle the failure scenario here.
      }
    } catch (e) {
      final snackBar = SnackBar(
        content: Text('Error adding new post: $e'),
        duration: const Duration(seconds: 2),
      );
      _scaffoldKey.currentState?.showSnackBar(snackBar);
      // Handle the error here.
    }
  }

  void deleteLocation() {
    final markersCollection = FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.email)
        .collection('Markers');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Are you sure you want to delete this location?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                try {
                  markersCollection
                      .where('name', isEqualTo: widget.name)
                      .where('description', isEqualTo: widget.description)
                      .where('type', isEqualTo: widget.type)
                      .get()
                      .then((snapshot) {
                    for (DocumentSnapshot ds in snapshot.docs) {
                      ds.reference.delete();
                    }
                  });
                  Navigator.of(context).pop();
                  const snackBar = SnackBar(
                    content: Text('Location deleted.'),
                    duration: Duration(seconds: 2),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                } catch (e) {
                  final snackBar = SnackBar(
                    content: Text('Error deleting location: $e'),
                    duration: const Duration(seconds: 2),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void currentUserMatchesMarkerOwnerPost() async {
    CollectionReference<Map<String, dynamic>> markerOwnerCollection =
        FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.email)
            .collection('Markers');

    QuerySnapshot<Map<String, dynamic>> markerOwnerSnapshot =
        await markerOwnerCollection
            .where('name', isEqualTo: widget.name)
            .where('description', isEqualTo: widget.description)
            .where('type', isEqualTo: widget.type)
            .get();

    if (markerOwnerSnapshot.docs.isNotEmpty) {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          markerOwnerSnapshot.docs.first;
      Map<String, dynamic>? markerOwnerData = docSnapshot.data();
      if (markerOwnerData != null &&
          markerOwnerData.containsKey('markerOwner')) {
        dynamic markerOwnerValue = markerOwnerData['markerOwner'];
        if (markerOwnerValue == currentUser.email) {
          Navigator.of(context).pop();
          postToCommunity();
          return;
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content:
              const Text('You are not the original owner of this location.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void currentUserMatchesMarkerOwnerDelete() async {
    CollectionReference<Map<String, dynamic>> markerOwnerCollection =
        FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.email)
            .collection('Markers');

    QuerySnapshot<Map<String, dynamic>> markerOwnerSnapshot =
        await markerOwnerCollection
            .where('name', isEqualTo: widget.name)
            .where('description', isEqualTo: widget.description)
            .where('type', isEqualTo: widget.type)
            .get();

    if (markerOwnerSnapshot.docs.isNotEmpty) {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          markerOwnerSnapshot.docs.first;
      Map<String, dynamic>? markerOwnerData = docSnapshot.data();
      if (markerOwnerData != null &&
          markerOwnerData.containsKey('markerOwner')) {
        dynamic markerOwnerValue = markerOwnerData['markerOwner'];
        if (markerOwnerValue == currentUser.email) {
          Navigator.of(context).pop();
          postToCommunity();
          return;
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content:
              const Text('You are not the original owner of this location.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'lib/assets/images/${widget.type.toLowerCase()}_marker.png',
            width: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 200, // Explicitly set the height
                width: double.infinity, // Use the full width of the parent
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrl, // Use the state variable for dynamic updates
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon:
                              const Icon(Icons.edit, color: Colors.deepOrange),
                          onPressed: pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoSection(
              context,
              icon: Icons.info_outline_rounded,
              title: 'What makes this location special?',
              content: widget.description,
            ),
            const Divider(height: 20, thickness: 1),
            _buildInfoSection(
              context,
              icon: Icons.calendar_month_rounded,
              title: 'When did you discover this location?',
              content: widget.timestamp,
            ),
            const Divider(height: 20, thickness: 1),
            _buildCoordinateSection(),
            const Divider(height: 20, thickness: 1),
            _buildOwnerSection(),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.blueGrey.shade700,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  lat: widget.lat,
                  lng: widget.lng,
                  followUser: false,
                  currentIndex: 1,
                ),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.map_outlined, color: Colors.blueGrey),
                  SizedBox(width: 10),
                  Text('Go to this Location',
                      style: TextStyle(fontSize: 18, color: Colors.black)),
                ],
              ),
              const Icon(Icons.double_arrow_outlined, color: Colors.deepOrange),
            ],
          ),
        ),
        const SizedBox(height: 5),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.blueGrey.shade700,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            currentUserMatchesMarkerOwnerPost();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.directions_outlined, color: Colors.blueGrey),
                  SizedBox(width: 10),
                  Text('Share with the community',
                      style: TextStyle(fontSize: 18, color: Colors.black)),
                ],
              ),
              const Icon(Icons.double_arrow_outlined, color: Colors.deepOrange),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.deepOrange),
            const SizedBox(width: 5),
            const Text('Your location will be become public',
                style: TextStyle(color: Colors.blueGrey)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.blueGrey.shade700),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close, color: Colors.blueGrey),
              label:
                  const Text('Close', style: TextStyle(color: Colors.blueGrey)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context,
      {required IconData icon,
      required String title,
      required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.deepOrange),
            const SizedBox(width: 5),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.deepOrange,
            ),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pin_drop_outlined, color: Colors.deepOrange),
            const SizedBox(width: 5),
            const Text(
              'Coordinates: ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.deepOrange,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lat: ${widget.lat.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Text('Lng: ${widget.lng.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOwnerSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline_rounded, color: Colors.deepOrange),
            const SizedBox(width: 5),
            const Text(
              "Owner: ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        Text(widget.markerOwner,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
