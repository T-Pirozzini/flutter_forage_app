import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/friend_request.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/screens/profile/profile_page.dart';
import 'package:flutter_forager_app/shared/gamification/gamification_helper.dart';
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
      final friendRepo = ref.read(friendRepositoryProvider);

      // Search for users using repository
      final allUsers = await userRepo.searchByUsername(query);

      // Check friend status for each user using new subcollection-based system
      final List<UserModel> results = [];
      for (final user in allUsers) {
        if (user.email != currentUser.email) {
          final isFriend = await friendRepo.areFriends(currentUser.email!, user.email);
          final hasPendingRequest = await friendRepo.hasPendingRequest(currentUser.email!, user.email);
          results.add(user.copyWith(
            isFriend: isFriend,
            hasPendingRequest: hasPendingRequest,
          ));
        }
      }

      setState(() {
        _searchResults = results;
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
      final friendRepo = ref.read(friendRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      // Get current user data for display name
      final currentUserData = await userRepo.getById(currentUser.email!);

      await friendRepo.sendRequest(
        fromEmail: currentUser.email!,
        fromDisplayName: currentUserData?.username ?? currentUser.email!,
        fromPhotoUrl: currentUserData?.profilePic,
        toEmail: recipientEmail,
      );

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
    final friendRepo = ref.read(friendRepositoryProvider);

    return StreamBuilder<List<FriendRequestModel>>(
      stream: friendRepo.streamIncomingRequests(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No pending requests'));
        }

        final requests = snapshot.data!;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: 8.0, vertical: 4.0),
              child: ListTile(
                leading: FutureBuilder<String>(
                  future: _getProfileImageUrl(request.fromPhotoUrl ?? ''),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return CircleAvatar(
                        backgroundImage: NetworkImage(snapshot.data!),
                      );
                    }
                    return CircleAvatar(
                      child: Text(request.fromDisplayName.isNotEmpty
                          ? request.fromDisplayName[0].toUpperCase()
                          : '?'),
                    );
                  },
                ),
                title: Text(request.fromDisplayName),
                subtitle: Text(request.fromEmail),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _handleRequest(
                          context, userId, request.id, request.fromEmail, true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _handleRequest(
                          context, userId, request.id, request.fromEmail, false),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSentRequests(String userId) {
    final friendRepo = ref.read(friendRepositoryProvider);

    return StreamBuilder<List<FriendRequestModel>>(
      stream: friendRepo.streamOutgoingRequests(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No sent requests'));
        }

        final requests = snapshot.data!;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];

            return Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: 8.0, vertical: 4.0),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(request.toDisplayName.isNotEmpty
                      ? request.toDisplayName[0].toUpperCase()
                      : request.toEmail[0].toUpperCase()),
                ),
                title: Text(request.toDisplayName.isNotEmpty
                    ? request.toDisplayName
                    : request.toEmail),
                subtitle: Text('Status: ${request.status.name.capitalize()}'),
                trailing: request.isPending
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            _cancelRequest(context, userId, request.toEmail),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleRequest(BuildContext context, String userId,
      String requestId, String fromEmail, bool accept) async {
    try {
      final friendRepo = ref.read(friendRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      if (accept) {
        // Get current user data for the friend relationship
        final currentUserData = await userRepo.getById(userId);

        await friendRepo.acceptRequest(
          userId: userId,
          requestId: requestId,
          userDisplayName: currentUserData?.username ?? userId,
          userPhotoUrl: currentUserData?.profilePic,
        );

        // Award points for adding friend
        if (mounted) {
          await GamificationHelper.awardFriendAdded(
            context: context,
            ref: ref,
            userId: userId,
          );
        }
      } else {
        await friendRepo.declineRequest(userId, requestId);
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
      BuildContext context, String userId, String recipientEmail) async {
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
        final friendRepo = ref.read(friendRepositoryProvider);

        await friendRepo.cancelRequest(userId, recipientEmail);

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
