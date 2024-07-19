import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
      scrollable: false,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            Image.asset(
                'lib/assets/images/${widget.type.toLowerCase()}_marker.png',
                width: 40),
            const SizedBox(width: 10),
            Text(
              widget.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
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
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded),
                    SizedBox(width: 5),
                    Text('What makes this location special? ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.deepOrange,
                      ),
                    ),
                    child: Text(widget.description)),
              ],
            ),
            const Divider(height: 10, thickness: 2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_rounded),
                    SizedBox(width: 5),
                    Text(
                      'When did you discover this location? ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.deepOrange,
                      ),
                    ),
                    child: Text(widget.timestamp)),
              ],
            ),
            const Divider(height: 10, thickness: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pin_drop_outlined),
                SizedBox(width: 5),
                Text('Coordinates of forage location: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 2),
            Center(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.deepOrange,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('Lat: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(widget.lat.toStringAsFixed(2)),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        const Text('Lng: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(widget.lng.toStringAsFixed(2)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 20, thickness: 2),
            Center(
                child: Row(
              children: [
                const Icon(Icons.person_outline_rounded),
                const SizedBox(width: 5),
                const Text("Owner: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.markerOwner),
              ],
            )),
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
                  currentIndex: 1,
                ),
              ),
            );
          },
          child: Row(
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
        const SizedBox(height: 5),
        ElevatedButton(
          onPressed: () {
            currentUserMatchesMarkerOwnerPost();
          },
          child: Row(
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.deepOrange),
            SizedBox(width: 5),
            Text('Your location will be become public'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }
}
