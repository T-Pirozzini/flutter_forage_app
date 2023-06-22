import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'forage_locations_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late final TextEditingController _searchController;
  List<Map<String, dynamic>> _searchResults = [];
  final currentUser = FirebaseAuth.instance.currentUser!;

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

  // search for users
  Future<void> _searchUsers(String searchTerm) async {
    final usersCollection = FirebaseFirestore.instance.collection('Users');
    final querySnapshot =
        await usersCollection.where('email', isEqualTo: searchTerm).get();

    setState(() {
      _searchResults = querySnapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> _sendFriendRequest(String userEmail) async {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    final usersCollection = FirebaseFirestore.instance.collection('Users');

    // Add the friend request to the selected user's list
    await usersCollection.doc(userEmail).update({
      'friendRequests': FieldValue.arrayUnion([currentUserEmail]),
    });

    // Add the selected user to the current user's sent friend requests list
    await usersCollection.doc(currentUserEmail).update({
      'sentFriendRequests': FieldValue.arrayUnion([userEmail]),
    });

    // Perform any additional UI updates or show a success message
  }

  // navigate to forage locations page
  void goToForageLocationsPage(String friendId) {
    // pop menu drawer
    Navigator.pop(context);
    // go to new page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForageLocations(userId: friendId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FRIENDS'),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade400,
      ),
      body: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => _searchUsers(value),
            decoration: const InputDecoration(
              hintText: 'Search users...',
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  title: Text(user['username'] ?? ''),
                  subtitle: Text(user['email'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _sendFriendRequest(user['email']),
                  ),
                );
              },
            ),
          ),
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
                      const Text('Your Friends'),
                      Expanded(
                        child: ListView.builder(
                          itemCount: userData['friends'].length,
                          itemBuilder: (context, index) {
                            final friendId = userData['friends'][index];
                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(friendId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final friendData = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  final friendEmail = friendData['email'];
                                  final friendUsername = friendData['username'];
                                  final friendProfilePic =
                                      friendData['profilePic'];

                                  return GestureDetector(
                                    onTap: () =>
                                        goToForageLocationsPage(friendId),
                                    child: ListTile(
                                      title: Text(friendUsername),
                                      subtitle: Text(friendEmail),
                                      leading: const Icon(Icons.person),
                                    ),
                                  );
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
