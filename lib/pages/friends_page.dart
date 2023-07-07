import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'forage_locations_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late final TextEditingController _searchController;
  List<Map<String, dynamic>> _searchResults = [];
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool _isLoading = false;

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

    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
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

    // Add the friend request to the selected user's list
    await usersCollection.doc(userEmail).update({
      'friendRequests': FieldValue.arrayUnion([
        {'email': currentUserEmail, 'timestamp': timeSent}
      ]),
    });

    // Add the selected user to the current user's sent friend requests list
    await usersCollection.doc(currentUserEmail).update({
      'sentFriendRequests': FieldValue.arrayUnion([
        {'email': currentUserEmail, 'timestamp': timeSent},
      ]),
    });
  }

  // navigate to forage locations page
  void goToForageLocationsPage(String friendId, String friendName) {
    // pop menu drawer
    Navigator.pop(context);
    // go to new page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForageLocations(
          userId: friendId,
          userName: friendName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FRIENDS',
          style: TextStyle(letterSpacing: 2.5),
        ),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade400,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _searchUsers(value),
              decoration: const InputDecoration(
                hintText: 'Search users...',
                contentPadding: EdgeInsets.all(8),
              ),
            ),
          ),
          SizedBox(
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
                  subtitle: Text(user['email'] ?? ''),
                  trailing: isFriend
                      ? Icon(Icons.check,
                          color: Colors
                              .green) // Display green checkmark for friends
                      : isFriendRequestSent
                          ? Icon(Icons.pending,
                              color: Colors
                                  .grey) // Display pending-related icon for friend requests sent
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
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(currentUser.email)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return Column(
                    children: [
                      const Text(
                        'Your Friends',
                        style: TextStyle(fontSize: 24),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: userData['friends'].length,
                          itemBuilder: (context, index) {
                            final friendObject = userData['friends'][index]
                                as Map<String, dynamic>;
                            final friendId = friendObject['email'];
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(friendId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final friendData = snapshot.data!.data();
                                  if (friendData != null &&
                                      friendData is Map<String, dynamic>) {
                                    final friendEmail = friendData['email'];
                                    final friendUsername =
                                        friendData['username'];
                                    final friendProfilePic =
                                        friendData['profilePic'];

                                    return GestureDetector(
                                      onTap: () => goToForageLocationsPage(
                                          friendId, friendUsername),
                                      child: ListTile(
                                        title: Text(friendUsername),
                                        subtitle: Text(friendEmail),
                                        leading: CircleAvatar(
                                          backgroundImage: friendProfilePic !=
                                                  null
                                              ? AssetImage(
                                                  'lib/assets/images/$friendProfilePic')
                                              : null,
                                          child: friendProfilePic == null
                                              ? const Icon(Icons.person)
                                              : null,
                                        ),
                                        trailing:
                                            const Icon(Icons.double_arrow),
                                        iconColor: Colors.deepOrange.shade400,
                                      ),
                                    );
                                  }
                                }
                                return const SizedBox();
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
