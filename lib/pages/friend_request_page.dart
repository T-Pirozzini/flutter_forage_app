import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FriendRequestPage extends StatefulWidget {
  const FriendRequestPage({super.key});

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage> {
  List<String> pendingFriendRequests = []; // List of pending friend requests
  List<String> sentFriendRequests = []; // List of sent friend requests
  // current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    // Initialize pendingFriendRequests and sentFriendRequests lists
    pendingFriendRequests = ['friend1', 'friend2'];
    sentFriendRequests = ['friend3', 'friend4'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FRIEND REQUESTS'),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade300,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  return Column(
                    children: [
                      const Text('Pending Friend Requests'),
                      Expanded(
                        child: ListView.builder(
                          itemCount: userData['friendRequests'].length,
                          itemBuilder: (context, index) {
                            final friendRequest =
                                userData['friendRequests'][index];
                            return ListTile(
                              title: Text(friendRequest),
                              leading: IconButton(
                                onPressed: () {
                                  // Add friend to friends list
                                  final currentUserEmail =
                                      FirebaseAuth.instance.currentUser!.email!;
                                  final usersCollection = FirebaseFirestore
                                      .instance
                                      .collection('Users');

                                  // Add friend to current user's friends list
                                  usersCollection.doc(currentUserEmail).update({
                                    'friends':
                                        FieldValue.arrayUnion([friendRequest])
                                  }).then((_) {
                                    // remove friend from current user's friend requests list
                                    usersCollection
                                        .doc(currentUserEmail)
                                        .update({
                                      'friendRequests': FieldValue.arrayRemove(
                                          [friendRequest])
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Friend added to current user\'s friends list'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }).catchError((error) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to add friend to current user\'s friends list: $error'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  });
                                },
                                icon: const Icon(Icons.person_add),
                                color: Colors.deepOrange,
                              ),
                              // Add any additional widgets or functionality for pending friend requests
                            );
                          },
                        ),
                      ),
                      const Text('Sent Friend Requests'),
                      Expanded(
                        child: ListView.builder(
                          itemCount: userData['sentFriendRequests'].length,
                          itemBuilder: (context, index) {
                            final sentFriendRequest =
                                userData['sentFriendRequests'][index];
                            return ListTile(
                              title: Text(sentFriendRequest),
                              leading: const Icon(Icons.person_add_disabled),
                            );
                          },
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
}
