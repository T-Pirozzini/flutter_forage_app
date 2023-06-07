import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser!;

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
            // get user data
            if (snapshot.hasData) {
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              return ListView(
                children: [
                  Text('Username: ${userData['username']}'),
                  Text(userData['email']),
                  Image.network(userData['profilePic'],
                      width: 100, height: 100, fit: BoxFit.contain),
                  Text(userData['bio']),
                  if (userData['friends'].length < 1)
                    const Text('You don\'t have any friends yet!')
                  else
                    Text(userData['friends'].toString()),
                  if (userData['friendRequests'].length < 1)
                    const Text('You don\'t have any friends requests.')
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
        ));
  }
}
