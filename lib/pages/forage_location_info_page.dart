import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';

class ForageLocationInfo extends StatefulWidget {
  final String name;
  final String description;
  final String imageUrl;
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
      required this.imageUrl,
      required this.timestamp,
      required this.type});

  @override
  State<ForageLocationInfo> createState() => _ForageLocationInfoState();
}

class _ForageLocationInfoState extends State<ForageLocationInfo> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  // current user
  final currentUser = FirebaseAuth.instance.currentUser!;

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
      });

      if (newPost.id.isNotEmpty) {
        final snackBar = SnackBar(
          content: Text('New post added with ID: ${newPost.id}'),
          duration: const Duration(seconds: 2),
        );
        _scaffoldKey.currentState?.showSnackBar(snackBar);
        // Success! You can perform any additional actions here.
      } else {
        final snackBar = SnackBar(
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
                  child: Center(
                    child: Image.network(widget.imageUrl, fit: BoxFit.cover),
                  ),
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
        ElevatedButton(
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.map_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Go to this Location', style: TextStyle(fontSize: 18)),
                ],
              ),
              Icon(Icons.double_arrow_outlined, color: Colors.white),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            postToCommunity();
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.directions_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Share with the community',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
              Icon(Icons.double_arrow_outlined, color: Colors.white),
            ],
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.deepOrange),
            SizedBox(width: 5),
            Text('Your location will be become public'),
          ],
        ),
        const SizedBox(height: 10),

        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton.icon(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete Location', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
          ],
        ),
        // ),
      ],
    );
  }
}
