import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
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
    getImage();
  }

  void goHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            return ListView(
              children: [
                Text('Username: ${userData['username']}'),
                Text(userData['email']),
                Image.network(
                  userData['profilePic'] ?? '', // Add null check
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                Text(userData['bio']),
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
                Image.network('http:/$_imagePath'),
                // Image.network('https://assetsio.reedpopcdn.com/dnd-5e-strixhaven-curriculum-of-chaos-artwork-3.jpg?width=1200&height=1200&fit=bounds&quality=70&format=jpg&auto=webp'),
                // Image.asset('/storage/emulated/0/Download/sweet_tooth_2.jpg'),
                // Image.asset('/documents/msf:1000000033'),
                Text('http:/$_imagePath'),
                // /data/user/0/com.example.flutter_forager_app/cache/4e3b3267-133e-4d58-a06b-f3fb8656a87b/sweet_tooth_2.jpg
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
    );
  }
}
