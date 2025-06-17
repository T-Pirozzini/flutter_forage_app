import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/models/user.dart';
import 'package:flutter_forager_app/screens/profile/profile_page.dart';
import 'package:flutter_forager_app/services/friend_service.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../forage_locations/forage_locations_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<int> _getLocationCount(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Markers')
        .where('markerOwner', isEqualTo: userId)
        .get();
    return snapshot.size;
  }

  Future<String> _getProfileImageUrl(String imageName) async {
    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref('profile_images/$imageName');
      return await ref.getDownloadURL();
    } catch (e) {
      return ''; // Return empty string if image not found
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final currentUserDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .get();
      final currentUserData = UserModel.fromFirestore(currentUserDoc);

      final results = await Future.wait(snapshot.docs.map((doc) async {
        final user = UserModel.fromFirestore(doc);
        final isFriend = currentUserData.friends.contains(user.email);
        return user.copyWith(isFriend: isFriend);
      }));

      setState(() {
        _searchResults =
            results.where((user) => user.email != currentUser.email).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching users: $e')),
      );
    }
  }

  void _navigateToFriendLocations(BuildContext context, UserModel friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForageLocations(
          userId: friend.email,
          userName: friend.username,
          userLocations: true,
        ),
      ),
    );
  }

  void _navigateToProfilePage(BuildContext context, UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(user: user, showBackButton: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: StyledTitleLarge('Friends', color: Colors.white),
        backgroundColor: Colors.deepOrange.shade300,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Show search results or friends list
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isNotEmpty
                    ? _buildSearchResults()
                    : _buildFriendsList(currentUser.email!),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: FutureBuilder<String>(
              future: _getProfileImageUrl(user.profilePic),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return CircleAvatar(
                    backgroundImage: NetworkImage(snapshot.data!),
                  );
                }
                return CircleAvatar(
                  child: Text(user.username[0].toUpperCase()),
                );
              },
            ),
            title: Text(user.username),
            subtitle: Text(user.email),
            trailing: user.isFriend
                ? const Icon(Icons.check, color: Colors.green)
                : IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: () => _sendFriendRequest(user.email),
                  ),
            onTap: () {
              if (user.isFriend) {
                _navigateToProfilePage(context, user);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildFriendsList(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = UserModel.fromFirestore(snapshot.data!);

        if (user.friends.isEmpty) {
          return const Center(
            child: Text(
              'No friends yet. Search for users to add friends!',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          itemCount: user.friends.length,
          itemBuilder: (context, index) {
            final friendId = user.friends[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(friendId)
                  .get(),
              builder: (context, friendSnapshot) {
                if (!friendSnapshot.hasData) {
                  return const ListTile(title: Text('Loading...'));
                }

                final friend = UserModel.fromFirestore(friendSnapshot.data!);
                return FutureBuilder<int>(
                  future: _getLocationCount(friendId),
                  builder: (context, countSnapshot) {
                    final locationCount = countSnapshot.data ?? 0;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        leading: FutureBuilder<String>(
                          future: _getProfileImageUrl(friend.profilePic),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              return CircleAvatar(
                                backgroundImage: NetworkImage(snapshot.data!),
                              );
                            }
                            return CircleAvatar(
                              child: Text(friend.username[0].toUpperCase()),
                            );
                          },
                        ),
                        title: Text(friend.username),
                        subtitle: Text('$locationCount locations'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.person, color: Colors.blue),
                              onPressed: () =>
                                  _navigateToProfilePage(context, friend),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showRemoveFriendDialog(
                                  context, userId, friendId),
                            ),
                          ],
                        ),
                        onTap: () =>
                            _navigateToFriendLocations(context, friend),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _sendFriendRequest(String recipientEmail) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      await FriendsService()
          .sendFriendRequest(currentUser.email!, recipientEmail);

      setState(() {
        _searchResults = _searchResults.map((user) {
          if (user.email == recipientEmail) {
            return user.copyWith(isFriend: true);
          }
          return user;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }

  Future<void> _showRemoveFriendDialog(
      BuildContext context, String userId, String friendId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: const Text('Are you sure you want to remove this friend?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FriendsService().removeFriend(userId, friendId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend removed successfully')),
      );
    }
  }
}
