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
  List<Map<String, dynamic>> pendingFriendRequests =
      []; // List of pending friend requests
  List<Map<String, dynamic>> sentFriendRequests =
      []; // List of sent friend requests
  // current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    // Initialize pendingFriendRequests and sentFriendRequests lists
    pendingFriendRequests = [];
    sentFriendRequests = [];
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
                  final friendRequests =
                      userData['friendRequests'] as List<dynamic>;
                  final pendingFriendRequests = friendRequests
                      .map((request) => {
                            'email': request['email'],
                            'timestamp': request['timestamp'].toDate(),
                          })
                      .toList();
                  return Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Accept Friend Request?',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: pendingFriendRequests.length,
                          itemBuilder: (context, index) {
                            final friendRequest = pendingFriendRequests[index];
                            return ListTile(
                              title: Text(friendRequest['email']),
                              leading: IconButton(
                                onPressed: () {
                                  // Add friend to friends list
                                  final currentUserEmail =
                                      FirebaseAuth.instance.currentUser!.email!;
                                  final usersCollection = FirebaseFirestore
                                      .instance
                                      .collection('Users');

                                  // Generate the timestamp
                                  final timestamp = Timestamp.now();

                                  // Add friend to current user's friends list
                                  usersCollection.doc(currentUserEmail).update({
                                    'friends': FieldValue.arrayUnion([
                                      {
                                        'email': friendRequest['email'],
                                        'timestamp': timestamp
                                      }
                                    ])
                                  }).then((_) {
                                    // Remove friend from current user's friend requests list
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
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Sent Friend Requests',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: userData['sentFriendRequests'].length,
                          itemBuilder: (context, index) {
                            final sentFriendRequest =
                                userData['sentFriendRequests'][index];
                            final sentDate = sentFriendRequest['timestamp'];
                            final daysAgo = calculateDaysAgo(sentDate);
                            return ListTile(
                              title: Text(sentFriendRequest['email']),
                              leading: const Icon(Icons.person),
                              trailing: Text(daysAgo),
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

  String calculateDaysAgo(Timestamp timestamp) {
    final now = Timestamp.now().toDate();
    final sentDate = timestamp.toDate();
    final difference = now.difference(sentDate).inDays;
    return '$difference days ago';
  }
}
