import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';

class ForageLocationInfo extends StatefulWidget {
  final String name;
  final String description;
  final String? image;
  final double lat;
  final double lng;
  final String timestamp;
  final String type;

  const ForageLocationInfo(
      {super.key,
      required this.name,
      required this.description,
      required this.lat,
      required this.lng,
      this.image,
      required this.timestamp,
      required this.type});

  @override
  State<ForageLocationInfo> createState() => _ForageLocationInfoState();
}

class _ForageLocationInfoState extends State<ForageLocationInfo> {

  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  Future<bool> loadImage() async {
    if (widget.image != null && await File(widget.image!).exists()) {
      return true;
    } else {
      return false;
    }
  }

  Widget buildImage() {
    return FutureBuilder<bool>(
      future: loadImage(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          print('Error loading image: ${snapshot.error}');
          return Image.asset(
            'lib/assets/images/friends.png',
            fit: BoxFit.cover,
          );
        } else if (snapshot.data == true) {
          return Image.file(
            File(widget.image!),
            fit: BoxFit.cover,
          );
        } else {
          return Image.asset(
            'lib/assets/images/missing_image.png',
            fit: BoxFit.contain,
          );
        }
      },
    );
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
    });

    if (newPost.id.isNotEmpty) {
      print('New post added with ID: ${newPost.id}');
      final snackBar = SnackBar(
          content: Text('New post added with ID: ${newPost.id}'),
          duration: const Duration(seconds: 2),
        );
        _scaffoldKey.currentState?.showSnackBar(snackBar);
      // Success! You can perform any additional actions here.
    } else {
      print('Failed to add new post.');
      final snackBar = SnackBar(
          content: const Text('Failed to add new post.'),
          duration: const Duration(seconds: 2),
        );
        _scaffoldKey.currentState?.showSnackBar(snackBar);
      // Handle the failure scenario here.
    }
  } catch (e) {
    print('Error adding new post: $e');
    final snackBar = SnackBar(
        content: Text('Error adding new post: $e'),
        duration: const Duration(seconds: 2),
      );
      _scaffoldKey.currentState?.showSnackBar(snackBar);
    // Handle the error here.
  }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: false,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            Image.asset(
                'lib/assets/images/${widget.type.toLowerCase()}_marker.png',
                width: 50),
            const SizedBox(width: 10),
            Text(
              widget.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                height: 200,
                width: 400,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: buildImage(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline_rounded),
                    Text('Description: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(widget.description),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.calendar_month_rounded),
                    Text(
                      'Date/Time: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(widget.timestamp),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.pin_drop_outlined),
                Text('Location: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                const Text('Lat: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.lat.toStringAsFixed(2)),
                const SizedBox(width: 10),
                const Text('Lng: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.lng.toStringAsFixed(2)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  lat: widget.lat,
                  lng: widget.lng,
                  followUser: false,
                  currentIndex: 2,
                ),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.map_outlined, color: Colors.deepOrange),
              Text('Go to Location', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            postToCommunity();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.directions_outlined, color: Colors.deepOrange),
              Text('Share with Community', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.close, color: Color.fromRGBO(255, 87, 34, 1)),
              Text('Close'),
            ],
          ),
        ),
      ],
    );
  }
}
