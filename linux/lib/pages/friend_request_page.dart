import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FriendRequestPage extends StatefulWidget {
  const FriendRequestPage({Key? key}) : super(key: key);

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage> {
  // current user
  final currentUser = FirebaseAuth.instance.currentUser!;

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
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Accept Friend Request?',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: userData['friendRequests'].length,
                          itemBuilder: (context, index) {
                            final currentUserEmail =
                                FirebaseAuth.instance.currentUser!.email!;
                            final usersCollection =
                                FirebaseFirestore.instance.collection('Users');
                            final friendUserEmail =
                                userData['friendRequests'][index]['email'];
                            final friendUserTimestamp =
                                userData['friendRequests'][index]['timestamp'];

                            return ListTile(
                              title: Text(friendUserEmail),
                              leading: IconButton(
                                onPressed: () async {
                                  try {
                                    // Generate the timestamp
                                    final timestamp = Timestamp.now();

                                    // Add friend to current user's friends list
                                    await usersCollection
                                        .doc(currentUserEmail)
                                        .update({
                                      'friends': FieldValue.arrayUnion([
                                        {
                                          'email': friendUserEmail,
                                          'timestamp': timestamp,
                                        },
                                      ]),
                                    });

                                    // Remove request from friend's sentFriendRequest list
                                    await usersCollection
                                        .doc(friendUserEmail)
                                        .update({
                                      'sentFriendRequests':
                                          FieldValue.arrayRemove([
                                        {
                                          'email': currentUserEmail,
                                          'timestamp': friendUserTimestamp,
                                        }
                                      ])
                                    });

                                    // Remove friend from current user's friendRequests list
                                    await usersCollection
                                        .doc(currentUserEmail)
                                        .update({
                                      'friendRequests': FieldValue.arrayRemove([
                                        {
                                          'email': friendUserEmail,
                                          'timestamp': friendUserTimestamp,
                                        }
                                      ])
                                    });

                                    // Friend request removal completed successfully
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Friend request removed successfully.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  } catch (error) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $error'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
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
