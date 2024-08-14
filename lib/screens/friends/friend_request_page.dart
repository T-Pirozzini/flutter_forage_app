import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  List<Map<String, dynamic>> _searchResults = [];
  late final TextEditingController _searchController;

  @override
  void initState() {
    _searchController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('Users').get();

    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // search for users
  Future<void> _searchUsers(String searchTerm) async {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

    if (searchTerm.isEmpty || searchTerm == currentUserEmail) {
      // Clear results if the search term is empty or the same as the current user's email
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final usersCollection = FirebaseFirestore.instance.collection('Users');
    // Use a range query for a partial match
    final querySnapshot = await usersCollection
        .where('email', isNotEqualTo: currentUserEmail)
        .where('email', isGreaterThanOrEqualTo: searchTerm)
        .where('email', isLessThanOrEqualTo: searchTerm + '\uf8ff')
        .get();

    final currentUserData = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserEmail)
        .get()
        .then((snapshot) => snapshot.data());

    final List<dynamic> currentUserFriends =
        currentUserData?['friends'] ?? <dynamic>[];
    final List<dynamic> currentUserSentFriendRequests =
        currentUserData?['sentFriendRequests'] ?? <dynamic>[];

    setState(() {
      _searchResults = querySnapshot.docs.map((doc) {
        final userData = doc.data();
        final userEmail = userData['email'] ?? '';

        // Check if the searched user is already a friend
        final isFriend = currentUserFriends.any((friend) =>
            friend['email'] != null && friend['email'] == userEmail);

        // Check if the friend request is already sent
        final isFriendRequestSent = currentUserSentFriendRequests.any(
            (request) =>
                request['email'] != null && request['email'] == userEmail);

        // Return modified user data with isFriend and isFriendRequestSent flags
        return {
          ...userData,
          'isFriend': isFriend,
          'isFriendRequestSent': isFriendRequestSent,
        };
      }).toList();
    });
  }

  Future<void> _sendFriendRequest(String userEmail) async {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    final usersCollection = FirebaseFirestore.instance.collection('Users');
    final timeSent = Timestamp.now();

    // Check if the friend request is already sent or pending
    final userDoc = await usersCollection.doc(userEmail).get();
    final friendRequests = userDoc.data()?['friendRequests'] ?? <dynamic>[];
    final isFriendRequestSent = friendRequests.any((request) =>
        request['email'] != null && request['email'] == currentUserEmail);

    if (isFriendRequestSent) {
      // Show snackbar if the friend request is already pending
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Waiting for $userEmail to accept your request')),
      );
      return;
    }

    // Add the friend request to the selected user's list
    await usersCollection.doc(userEmail).update({
      'friendRequests': FieldValue.arrayUnion([
        {'email': currentUserEmail, 'timestamp': timeSent}
      ]),
    });

    // Add the selected user to the current user's sent friend requests list
    await usersCollection.doc(currentUserEmail).update({
      'sentFriendRequests': FieldValue.arrayUnion([
        {'email': userEmail, 'timestamp': timeSent},
      ]),
    });

    // Update the search results to reflect the change
    int userIndex =
        _searchResults.indexWhere((user) => user['email'] == userEmail);
    if (userIndex != -1) {
      setState(() {
        _searchResults[userIndex]['isFriendRequestSent'] = true;
        _searchController.clear();
      });
    }

    // Show snackbar after friend request is sent
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Friend request sent to ${userEmail.split('@')[0]}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 50,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _searchUsers(value),
                decoration: const InputDecoration(
                  hintText: 'Search users...',
                  contentPadding: EdgeInsets.all(8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  filled: true, // Enable the fill color
                  fillColor: Colors.white, // Set the fill color to white
                ),
              ),
            ),
          ),
          Visibility(
            visible: _searchResults.isNotEmpty,
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  final isFriend = user['isFriend'] ?? false;
                  final isFriendRequestSent =
                      user['isFriendRequestSent'] ?? false;

                  return ListTile(
                    title: Text(user['username'] ?? ''),
                    trailing: isFriend
                        ? const Icon(Icons.check,
                            color: Colors
                                .green) // Display green checkmark for friends
                        : isFriendRequestSent
                            ? const Icon(Icons.pending,
                                color: Colors
                                    .deepOrange) // Display pending-related icon for friend requests sent
                            : const Icon(
                                Icons.add), // Display plus sign for other users
                    onTap: () {
                      if (!isFriend && !isFriendRequestSent) {
                        _sendFriendRequest(user['email']);
                      }
                    },
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(currentUser.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final userData = snapshot.data!.data() as Map<String, dynamic>;

                return Column(
                  children: [
                    // Pending Friend Requests Section
                    if (userData['friendRequests'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Accept Friend Requests?',
                            style:
                                TextStyle(fontSize: 24, color: Colors.white)),
                      ),
                    _buildFriendRequestsSection(userData['friendRequests']),
                    // Sent Friend Requests Section
                    if (userData['sentFriendRequests'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Sent Friend Requests',
                            style:
                                TextStyle(fontSize: 24, color: Colors.white)),
                      ),
                    _buildSentFriendRequestsSection(
                        userData['sentFriendRequests']),
                  ],
                );
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

  Widget _buildFriendRequestsSection(List<dynamic> friendRequests) {
    if (friendRequests.isEmpty) return SizedBox.shrink();
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    final usersCollection = FirebaseFirestore.instance.collection('Users');

    return Expanded(
      child: ListView.builder(
        itemCount: friendRequests.length,
        itemBuilder: (context, index) {
          final friendRequest = friendRequests[index];
          final friendUserEmail = friendRequest['email'];
          final friendUserTimestamp = friendRequest['timestamp'];
          return ListTile(
            title: Text(friendUserEmail),
            leading: IconButton(
              onPressed: () async {
                try {
                  // Generate the timestamp
                  final timestamp = Timestamp.now();

                  // Add friend to current user's friends list
                  await usersCollection.doc(currentUserEmail).update({
                    'friends': FieldValue.arrayUnion([
                      {
                        'email': friendUserEmail,
                        'timestamp': timestamp,
                      },
                    ]),
                  });

                  // Add current user to friend requesters friends list
                  await usersCollection.doc(friendUserEmail).update({
                    'friends': FieldValue.arrayUnion([
                      {
                        'email': currentUserEmail,
                        'timestamp': timestamp,
                      },
                    ]),
                  });

                  // Remove request from friend's sentFriendRequest list
                  await usersCollection.doc(friendUserEmail).update({
                    'sentFriendRequests': FieldValue.arrayRemove([
                      {
                        'email': currentUserEmail,
                        'timestamp': friendUserTimestamp,
                      }
                    ])
                  });

                  // Remove friend from current user's pendingRequests list
                  await usersCollection.doc(currentUserEmail).update({
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
                      content: Text('Friend request removed successfully.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (error) {}
              },
              icon: const Icon(Icons.person_add),
              color: Colors.deepOrange,
            ),
            // Add any additional widgets or functionality for pending friend requests
          );
        },
      ),
    );
  }

  Widget _buildSentFriendRequestsSection(List<dynamic> sentFriendRequests) {
    if (sentFriendRequests.isEmpty) return SizedBox.shrink();

    return Expanded(
      child: ListView.builder(
        itemCount: sentFriendRequests.length,
        itemBuilder: (context, index) {
          final Map<String, dynamic> sentFriendRequest =
              sentFriendRequests[index];
          final Timestamp sentDate = sentFriendRequest['timestamp'];
          final String daysAgo = calculateDaysAgo(sentDate);
          return ListTile(
            title: Text(sentFriendRequest['email']),
            leading: const Icon(Icons.person),
            trailing: Text(daysAgo),
          );
        },
      ),
    );
  }
}
