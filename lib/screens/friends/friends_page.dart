import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/friend.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/data/services/migration_service.dart';
import 'package:flutter_forager_app/screens/profile/profile_page.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../forage_locations/forage_locations_page.dart';
import 'components/send_friend_request_dialog.dart';

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
        title: Text('Friends',
            style: AppTheme.heading(size: 20, color: Colors.white)),
        backgroundColor: AppTheme.primary,
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
          // Search bar with safety info
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.security, color: AppTheme.primary),
                  tooltip: 'Safety Tips',
                  onPressed: _showSafetyTipsDialog,
                ),
              ],
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
        final memberSince = user.createdAt.toDate();
        final daysSinceMember = DateTime.now().difference(memberSince).inDays;
        final activityLevel =
            _getActivityLevel(daysSinceMember, user.friends.length);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusMedium,
          ),
          child: InkWell(
            borderRadius: AppTheme.borderRadiusMedium,
            onTap: () {
              if (user.isFriend) {
                _navigateToProfilePage(context, user);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      FutureBuilder<String>(
                        future: _getProfileImageUrl(user.profilePic),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            return CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(snapshot.data!),
                            );
                          }
                          return CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primary,
                            child: Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : '?',
                              style: AppTheme.title(color: Colors.white),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.username,
                                    style: AppTheme.title(size: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _buildActivityBadge(activityLevel),
                                if (user.openToForage) ...[
                                  const SizedBox(width: 6),
                                  _buildBadge(
                                      'Open to Forage', AppTheme.success),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: AppTheme.caption(size: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Action button
                      if (user.isFriend)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check,
                              color: AppTheme.success, size: 20),
                        )
                      else if (user.hasPendingRequest)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.pending,
                              color: AppTheme.warning, size: 20),
                        )
                      else
                        IconButton(
                          icon: Icon(Icons.person_add, color: AppTheme.primary),
                          onPressed: () =>
                              _sendFriendRequest(user.email, user.username),
                        ),
                    ],
                  ),
                  // Reputation row
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildReputationItem(
                          Icons.calendar_today,
                          'Member since ${DateFormat('MMM yyyy').format(memberSince)}',
                        ),
                        _buildReputationItem(
                          Icons.people,
                          '${user.friends.length} friends',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getActivityLevel(int daysSinceMember, int friendCount) {
    // New: Less than 7 days OR less than 2 friends
    if (daysSinceMember < 7 || friendCount < 2) {
      return 'New';
    }
    // Active: More than 30 days AND more than 5 friends
    if (daysSinceMember > 30 && friendCount > 5) {
      return 'Active';
    }
    // Regular: Everything else
    return 'Regular';
  }

  Widget _buildActivityBadge(String level) {
    Color color;
    IconData icon;

    switch (level) {
      case 'Active':
        color = AppTheme.success;
        icon = Icons.verified;
        break;
      case 'New':
        color = AppTheme.info;
        icon = Icons.new_releases;
        break;
      default:
        color = AppTheme.textMedium;
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            level,
            style: AppTheme.caption(
              size: 10,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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
                return _buildFriendCard(
                  friend: friend,
                  locationCount: locationCount,
                  userId: userId,
                  userRepo: userRepo,
                  friendRepo: friendRepo,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFriendCard({
    required FriendModel friend,
    required int locationCount,
    required String userId,
    required dynamic userRepo,
    required dynamic friendRepo,
  }) {
    return FutureBuilder<UserModel?>(
      future: userRepo.getById(friend.friendEmail),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data;
        final isOpenToForage = userData?.openToForage ?? false;
        final memberSince = userData?.createdAt.toDate();
        final friendCount = userData?.friends.length ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusMedium,
            side: friend.closeFriend
                ? BorderSide(color: AppTheme.xp, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: AppTheme.borderRadiusMedium,
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
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar with close friend badge
                      Stack(
                        children: [
                          FutureBuilder<String>(
                            future: _getProfileImageUrl(friend.photoUrl ?? ''),
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data!.isNotEmpty) {
                                return CircleAvatar(
                                  radius: 24,
                                  backgroundImage: NetworkImage(snapshot.data!),
                                );
                              }
                              return CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primary,
                                child: Text(
                                  friend.displayName.isNotEmpty
                                      ? friend.displayName[0].toUpperCase()
                                      : '?',
                                  style: AppTheme.title(color: Colors.white),
                                ),
                              );
                            },
                          ),
                          if (friend.closeFriend)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppTheme.xp,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Friend info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    friend.displayName,
                                    style: AppTheme.title(size: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (friend.closeFriend) ...[
                                  const SizedBox(width: 6),
                                  _buildBadge('Close Friend', AppTheme.xp),
                                ],
                                if (isOpenToForage) ...[
                                  const SizedBox(width: 6),
                                  _buildBadge(
                                      'Open to Forage', AppTheme.success),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 14, color: AppTheme.textMedium),
                                const SizedBox(width: 4),
                                Text(
                                  '$locationCount locations',
                                  style: AppTheme.caption(size: 12),
                                ),
                                const SizedBox(width: 10),
                                Icon(Icons.people,
                                    size: 12, color: AppTheme.textMedium),
                                const SizedBox(width: 4),
                                Text(
                                  '$friendCount friends',
                                  style: AppTheme.caption(size: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Close Friend toggle
                          IconButton(
                            icon: Icon(
                              friend.closeFriend
                                  ? Icons.star
                                  : Icons.star_border,
                              color: friend.closeFriend
                                  ? AppTheme.xp
                                  : AppTheme.textMedium,
                            ),
                            tooltip: friend.closeFriend
                                ? 'Remove from Close Friends'
                                : 'Add to Close Friends',
                            onPressed: () => _toggleCloseFriend(
                              userId,
                              friend.friendEmail,
                              !friend.closeFriend,
                            ),
                          ),
                          // Emergency Contact toggle
                          IconButton(
                            icon: Icon(
                              friend.isEmergencyContact
                                  ? Icons.shield
                                  : Icons.shield_outlined,
                              color: friend.isEmergencyContact
                                  ? AppTheme.warning
                                  : AppTheme.textMedium,
                            ),
                            tooltip: friend.isEmergencyContact
                                ? 'Remove as Emergency Contact'
                                : 'Set as Emergency Contact',
                            onPressed: () => _toggleEmergencyContact(
                              userId,
                              friend.friendEmail,
                              !friend.isEmergencyContact,
                            ),
                          ),
                          // View profile
                          IconButton(
                            icon: Icon(Icons.person, color: AppTheme.info),
                            tooltip: 'View Profile',
                            onPressed: () async {
                              if (userData != null && mounted) {
                                _navigateToProfilePage(context, userData);
                              } else {
                                final freshData =
                                    await userRepo.getById(friend.friendEmail);
                                if (freshData != null && mounted) {
                                  _navigateToProfilePage(context, freshData);
                                }
                              }
                            },
                          ),
                          // Remove friend
                          IconButton(
                            icon: Icon(Icons.person_remove,
                                color: AppTheme.error),
                            tooltip: 'Remove Friend',
                            onPressed: () => _showRemoveFriendDialog(
                                context, userId, friend.friendEmail),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Reputation indicators row
                  if (memberSince != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildReputationItem(
                            Icons.calendar_today,
                            'Member since ${DateFormat('MMM yyyy').format(memberSince)}',
                          ),
                          _buildReputationItem(
                            Icons.handshake,
                            'Friends since ${DateFormat('MMM yyyy').format(friend.addedAt)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTheme.caption(
          size: 10,
          weight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildReputationItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textMedium),
        const SizedBox(width: 4),
        Text(text, style: AppTheme.caption(size: 11)),
      ],
    );
  }

  Future<void> _toggleCloseFriend(
      String userId, String friendEmail, bool isCloseFriend) async {
    try {
      final friendRepo = ref.read(friendRepositoryProvider);
      await friendRepo.setCloseFriend(userId, friendEmail, isCloseFriend);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCloseFriend
                  ? 'Added to Close Friends! They can now see precise locations.'
                  : 'Removed from Close Friends.',
            ),
            backgroundColor: isCloseFriend ? AppTheme.success : AppTheme.info,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating close friend status: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleEmergencyContact(
      String userId, String friendEmail, bool isEmergencyContact) async {
    try {
      final friendRepo = ref.read(friendRepositoryProvider);
      await friendRepo.setEmergencyContact(
          userId, friendEmail, isEmergencyContact);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEmergencyContact
                  ? 'Added as Emergency Contact! They\'ll be notified when you plan foraging meetups.'
                  : 'Removed as Emergency Contact.',
            ),
            backgroundColor:
                isEmergencyContact ? AppTheme.warning : AppTheme.info,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating emergency contact status: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(
      String recipientEmail, String recipientUsername) async {
    // Show dialog with optional message
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => SendFriendRequestDialog(
        recipientUsername: recipientUsername,
        recipientEmail: recipientEmail,
      ),
    );

    // User cancelled
    if (result == null || result['send'] != true) return;

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
        message: result['message'] as String?,
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
          SnackBar(
            content: const Text('Friend request sent!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showSafetyTipsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        title: Row(
          children: [
            Icon(Icons.security, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('Foraging Safety Tips', style: AppTheme.title(size: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stay safe while connecting with other foragers:',
                style: AppTheme.body(size: 14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildSafetyTipItem(
                Icons.location_on,
                'Meet in public first',
                'Choose a trailhead, parking lot, or public area for first meetups.',
              ),
              _buildSafetyTipItem(
                Icons.share_location,
                'Share your plans',
                'Tell someone where you\'re going and when you\'ll be back.',
              ),
              _buildSafetyTipItem(
                Icons.group,
                'Forage in groups',
                'There\'s safety in numbers. Consider group foraging trips.',
              ),
              _buildSafetyTipItem(
                Icons.psychology,
                'Trust your instincts',
                'If something feels off, leave. Your safety comes first.',
              ),
              _buildSafetyTipItem(
                Icons.phone,
                'Keep your phone charged',
                'Ensure you have a way to call for help if needed.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock, size: 16, color: AppTheme.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your precise locations are only shared with Close Friends. Regular friends see approximate areas (~500m radius).',
                        style: AppTheme.caption(size: 12, color: AppTheme.info),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!',
                style: AppTheme.button(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTipItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTheme.caption(size: 13, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description, style: AppTheme.caption(size: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showSafetyConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        title: Row(
          children: [
            Icon(Icons.person_add, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('Connect with a Forager', style: AppTheme.title(size: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'re about to send a friend request. Once accepted, you\'ll be able to see each other\'s shared locations.',
              style: AppTheme.body(size: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppTheme.info),
                      const SizedBox(width: 6),
                      Text(
                        'Location Privacy',
                        style: AppTheme.caption(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppTheme.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Regular friends see approximate locations (~500m radius). Mark someone as a "Close Friend" to share precise coordinates.',
                    style: AppTheme.caption(size: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppTheme.button(color: AppTheme.textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: Text('Send Request', style: AppTheme.button()),
          ),
        ],
      ),
    );
    return result ?? false;
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
