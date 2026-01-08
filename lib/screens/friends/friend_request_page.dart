import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/screens/profile/profile_page.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FriendRequestPage extends ConsumerStatefulWidget {
  const FriendRequestPage({Key? key}) : super(key: key);

  @override
  ConsumerState<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends ConsumerState<FriendRequestPage> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _getProfileImageUrl(String imageName) async {
    try {
      // Use default profile image if imageName is empty
      final imagePath = imageName.isEmpty ? 'profileImage1.jpg' : imageName;
      final ref = firebase_storage.FirebaseStorage.instance
          .ref('profile_images/$imagePath');
      return await ref.getDownloadURL();
    } catch (e) {
      // Fallback to default profile image URL if there's an error
      final ref = firebase_storage.FirebaseStorage.instance
          .ref('profile_images/profileImage1.jpg');
      try {
        return await ref.getDownloadURL();
      } catch (e) {
        // If default image also fails, return empty string or handle differently
        print('Error fetching default profile image: $e');
        return '';
      }
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
      final userRepo = ref.read(userRepositoryProvider);

      // Search for users using repository
      final allUsers = await userRepo.searchByUsername(query);

      // Get current user data to check friend status
      final currentUserData = await userRepo.getById(currentUser.email!);

      if (currentUserData == null) {
        setState(() {
          _isSearching = false;
        });
        return;
      }

      final results = allUsers.map((user) {
        final isFriend = currentUserData.friends.contains(user.email);
        final hasPendingRequest = currentUserData.friendRequests
                .containsKey(user.email) ||
            (currentUserData.sentFriendRequests != null &&
                currentUserData.sentFriendRequests!.containsKey(user.email));
        return user.copyWith(
          isFriend: isFriend,
          hasPendingRequest: hasPendingRequest,
        );
      }).toList();

      setState(() {
        _searchResults =
            results.where((user) => user.email != currentUser.email).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $e')),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(String recipientEmail) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final userRepo = ref.read(userRepositoryProvider);

      await userRepo.sendFriendRequest(currentUser.email!, recipientEmail);

      setState(() {
        _searchResults = _searchResults.map((user) {
          if (user.email == recipientEmail) {
            return user.copyWith(hasPendingRequest: true);
          }
          return user;
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    }
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const StyledTitleLarge('Friend Requests', color: Colors.white),
          backgroundColor: Colors.deepOrange.shade300,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
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

            // Show search results or tabs
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isNotEmpty
                      ? _buildSearchResults()
                      : _buildRequestTabs(currentUser.email!),
            ),
          ],
        ),
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
            trailing: user.isFriend
                ? const Icon(Icons.check, color: Colors.green)
                : user.hasPendingRequest
                    ? const Icon(Icons.pending, color: Colors.orange)
                    : IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () => _sendFriendRequest(user.email),
                      ),
            onTap: () {
              _navigateToProfilePage(context, user);
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestTabs(String userId) {
    return TabBarView(
      children: [
        // Received requests tab
        _buildReceivedRequests(userId),
        // Sent requests tab
        _buildSentRequests(userId),
      ],
    );
  }

  Widget _buildReceivedRequests(String userId) {
    final userRepo = ref.read(userRepositoryProvider);

    return StreamBuilder<UserModel?>(
      stream: userRepo.streamById(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data!;
        final pendingRequests = user.pendingIncomingRequests;

        if (pendingRequests.isEmpty) {
          return const Center(child: Text('No pending requests'));
        }

        return ListView.builder(
          itemCount: pendingRequests.length,
          itemBuilder: (context, index) {
            final requesterId = pendingRequests[index];
            return FutureBuilder<UserModel?>(
              future: userRepo.getById(requesterId),
              builder: (context, requesterSnapshot) {
                if (!requesterSnapshot.hasData || requesterSnapshot.data == null) {
                  return const ListTile(title: Text('Loading...'));
                }

                final requester = requesterSnapshot.data!;
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: FutureBuilder<String>(
                      future: _getProfileImageUrl(requester.profilePic),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return CircleAvatar(
                            backgroundImage: NetworkImage(snapshot.data!),
                          );
                        }
                        return CircleAvatar(
                          child: Text(requester.username[0].toUpperCase()),
                        );
                      },
                    ),
                    title: Text(requester.username),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _handleRequest(
                              context, userId, requesterId, true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _handleRequest(
                              context, userId, requesterId, false),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSentRequests(String userId) {
    final userRepo = ref.read(userRepositoryProvider);

    return StreamBuilder<UserModel?>(
      stream: userRepo.streamById(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data!;
        final sentRequests = user.sentFriendRequests?.keys.toList() ?? <String>[];

        if (sentRequests.isEmpty) {
          return const Center(child: Text('No sent requests'));
        }

        return ListView.builder(
          itemCount: sentRequests.length,
          itemBuilder: (context, index) {
            final recipientId = sentRequests[index];
            return FutureBuilder<UserModel?>(
              future: userRepo.getById(recipientId),
              builder: (context, recipientSnapshot) {
                if (!recipientSnapshot.hasData || recipientSnapshot.data == null) {
                  return const ListTile(title: Text('Loading...'));
                }

                final recipient = recipientSnapshot.data!;
                final status = user.sentFriendRequests?[recipientId] ?? 'pending';

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: FutureBuilder<String>(
                      future: _getProfileImageUrl(recipient.profilePic),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return CircleAvatar(
                            backgroundImage: NetworkImage(snapshot.data!),
                          );
                        }
                        return CircleAvatar(
                          child: Text(recipient.username[0].toUpperCase()),
                        );
                      },
                    ),
                    title: Text(recipient.username),
                    subtitle: Text('Status: ${status.capitalize()}'),
                    trailing: status == 'pending'
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                _cancelRequest(context, userId, recipientId),
                          )
                        : null,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handleRequest(BuildContext context, String userId,
      String requesterId, bool accept) async {
    try {
      final userRepo = ref.read(userRepositoryProvider);

      if (accept) {
        await userRepo.acceptFriendRequest(userId, requesterId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend request accepted')),
          );
        }
      } else {
        await userRepo.rejectFriendRequest(userId, requesterId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend request rejected')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to handle request: $e')),
        );
      }
    }
  }

  Future<void> _cancelRequest(
      BuildContext context, String userId, String recipientId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content:
            const Text('Are you sure you want to cancel this friend request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final userRepo = ref.read(userRepositoryProvider);

        // Use the rejectFriendRequest method which handles both sides
        await userRepo.rejectFriendRequest(recipientId, userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request cancelled')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel request: $e')),
          );
        }
      }
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
