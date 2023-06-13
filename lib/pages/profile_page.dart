import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  // all users
  final usersCollection = FirebaseFirestore.instance.collection('Users');

  // profile UI
  final double coverHeight = 280.0;
  final double profileHeight = 144.0;

  // edit field
  Future<void> editField(String field) async {
    String newValue = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Edit $field",
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $field",
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            newValue = value;
          },
        ),
        actions: [
          // cancel button
          TextButton(
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),

          // save button
          TextButton(
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.of(context).pop(newValue),
          ),
        ],
      ),
    );

    // update in Firestore
    if (newValue.trim().isNotEmpty) {
      // only update if there is something in the textfield
      await usersCollection.doc(currentUser.email).update(
        {
          field: newValue,
        },
      );
    }
  }

  // image paths
  late String _imagePath = '';
  final String _imagePath2 =
      'https://assetsio.reedpopcdn.com/dnd-5e-strixhaven-curriculum-of-chaos-artwork-3.jpg?width=1200&height=1200&fit=bounds&quality=70&format=jpg&auto=webp';

  Future<void> getImage() async {
    final markersSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.email)
        .collection('Markers')
        .doc('Qse0JD1kiTRlHJiEOxJK')
        .get();

    final markersData = markersSnapshot.data();

    if (markersData != null) {
      final imagePath = markersData['image'] as String?;
      if (imagePath != null) {
        setState(() {
          _imagePath = imagePath;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // getImage();
  }

  // back to main page
  void goHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange.shade200,
      body: Column(
        children: [
          buildTop(),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(currentUser.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return ListView(
                    children: [
                      Column(
                        children: [
                          Text(
                            userData['username'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 32),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            userData['email'],
                            style: const TextStyle(
                                fontSize: 24, color: Colors.black87),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(userData['bio']),
                          IconButton(
                            onPressed: () => editField('bio'),
                            icon: const Icon(Icons.edit),
                          ),
                        ],
                      ),
                      if (userData['friends'].length < 1)
                        const Text('You don\'t have any friends yet!')
                      else
                        Text(userData['friends'].toString()),
                      if (userData['friendRequests'].length < 1)
                        const Text('You don\'t have any friend requests.')
                      else
                        Text(userData['friendRequests'].toString()),
                      if (userData['sentFriendRequests'].length < 1)
                        const Text('You haven\'t sent any friend requests.')
                      else
                        Text(userData['sentFriendRequests'].toString()),
                      if (userData['posts'].length < 1)
                        const Text('You haven\'t posted anything yet.')
                      else
                        Text(userData['posts'].toString()),
                      Image.network(_imagePath2),
                      GestureDetector(
                        onTap: goHome,
                        child: Column(
                          children: const [
                            Icon(Icons.home, size: 100),
                            Text('Go home'),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTop() {
    final bottom = profileHeight / 2;
    final top = coverHeight - profileHeight / 2;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          child: buildCoverImage(),
        ),
        Positioned(
          top: top,
          child: buildProfileImage(),
        ),
      ],
    );
  }

  Widget buildCoverImage() => ClipPath(
        clipper: _BottomCurveClipper(),
        child: Container(
          color: Colors.grey,
          child: Image.network(
            'https://images.unsplash.com/photo-1602664719969-5cb83870efb3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1112&q=80',
            width: double.infinity,
            height: coverHeight,
            fit: BoxFit.cover,
          ),
        ),
      );

  Widget buildProfileImage() => Container(
        padding: const EdgeInsets.all(8.0), // Add padding around the circle
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4.0,
          ),
        ),
        child: CircleAvatar(
          radius: profileHeight / 2,
          backgroundColor: Colors.grey.shade800,
          backgroundImage: const NetworkImage(
            'https://i.scdn.co/image/ab67616d00001e0240e57e25851e7c9cf4275084',
          ),
        ),
      );
}

// curve for the background image
class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
        size.width / 2, size.height * 1.2, size.width, size.height - 80);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
