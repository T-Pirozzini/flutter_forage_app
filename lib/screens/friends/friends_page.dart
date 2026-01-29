import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/friend.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/data/services/migration_service.dart';
import 'package:flutter_forager_app/screens/profile/profile_page.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../forage_locations/forage_locations_page.dart';

class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  bool _isMigrating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Manually trigger migration of old friends from array to subcollection
  Future<void> _runFriendMigration() async {
    if (_isMigrating) return;

    setState(() => _isMigrating = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user logged in')),
          );
        }
        return;
      }

      final migrationService = MigrationService();
      final result = await migrationService.migrateFriendsToSubcollection(
        dryRun: false,
        specificUserId: currentUser!.email!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.migratedFriendships > 0
                  ? 'Migrated ${result.migratedFriendships} friends!'
                  : result.skippedFriendships > 0
                      ? 'All ${result.skippedFriendships} friends already migrated'
                      : 'No friends to migrate',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Migration error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMigrating = false);
      }
    }
  }

  Future<int> _getLocationCount(String userId) async {
    final markerRepo = ref.read(markerRepositoryProvider);
    final markers = await markerRepo.getByUserId(userId);
    return markers.length;
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
      final userRepo = ref.read(userRepositoryProvider);
      final friendRepo = ref.read(friendRepositoryProvider);

      // Search for users using repository
      final allUsers = await userRepo.searchByUsername(query);

      // Check friend status for each user using new subcollection-based system
      final List<UserModel> results = [];
      for (final user in allUsers) {
        if (user.email != currentUser.email) {
          final isFriend =
              await friendRepo.areFriends(currentUser.email!, user.email);
          final hasPendingRequest = await friendRepo.hasPendingRequest(
              currentUser.email!, user.email);
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
        actions: [
          // Migration button for importing old friends
          IconButton(
            icon: _isMigrating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync, color: Colors.white),
            tooltip: 'Import old friends',
            onPressed: _isMigrating ? null : _runFriendMigration,
          ),
        ],
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
                : user.hasPendingRequest
                    ? const Icon(Icons.pending, color: Colors.orange)
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
    final friendRepo = ref.read(friendRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    return StreamBuilder<List<FriendModel>>(
      stream: friendRepo.streamFriends(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No friends yet. Search for users to add friends!',
              textAlign: TextAlign.center,
            ),
          );
        }

        final friends = snapshot.data!;

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return FutureBuilder<int>(
              future: _getLocationCount(friend.friendEmail),
              builder: (context, countSnapshot) {
                final locationCount = countSnapshot.data ?? 0;
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: FutureBuilder<String>(
                      future: _getProfileImageUrl(friend.photoUrl ?? ''),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return CircleAvatar(
                            backgroundImage: NetworkImage(snapshot.data!),
                          );
                        }
                        return CircleAvatar(
                          child: Text(friend.displayName.isNotEmpty
                              ? friend.displayName[0].toUpperCase()
                              : '?'),
                        );
                      },
                    ),
                    title: Text(friend.displayName),
                    subtitle: Text('$locationCount locations'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person, color: Colors.blue),
                          onPressed: () async {
                            // Fetch full user data for profile page
                            final userData =
                                await userRepo.getById(friend.friendEmail);
                            if (userData != null && mounted) {
                              _navigateToProfilePage(context, userData);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showRemoveFriendDialog(
                              context, userId, friend.friendEmail),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navigate to friend's locations
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForageLocations(
                            userId: friend.friendEmail,
                            userName: friend.displayName,
                            userLocations: true,
                          ),
                        ),
                      );
                    },
                  ),
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

  Future<void> _showRemoveFriendDialog(
      BuildContext context, String userId, String friendEmail) async {
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
      try {
        final friendRepo = ref.read(friendRepositoryProvider);
        await friendRepo.removeFriend(userId, friendEmail);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend removed successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove friend: $e')),
          );
        }
      }
    }
  }
}
