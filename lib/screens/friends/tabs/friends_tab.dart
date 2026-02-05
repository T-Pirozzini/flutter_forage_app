import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/friend.dart';
import 'package:flutter_forager_app/data/models/location_sharing_info.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_locations_page.dart';
import 'package:flutter_forager_app/screens/friends/components/friend_card.dart';
import 'package:flutter_forager_app/screens/friends/components/notify_emergency_contact_dialog.dart';
import 'package:flutter_forager_app/screens/profile/profile_page.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Friends tab showing the user's friends list.
///
/// This tab is used within FriendsController and does NOT have its own AppBar
/// (the AppBar is provided by FriendsController).
class FriendsTab extends ConsumerStatefulWidget {
  const FriendsTab({super.key});

  @override
  ConsumerState<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<FriendsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == null) {
      return const Center(child: Text('Please log in to view friends'));
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search friends...',
              hintStyle: AppTheme.caption(color: AppTheme.textMedium),
              prefixIcon: Icon(Icons.search, color: AppTheme.textMedium),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.textMedium.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.textMedium.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.primary),
              ),
              filled: true,
              fillColor: AppTheme.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
        ),

        // Friends list
        Expanded(
          child: _buildFriendsList(currentUser!.email!),
        ),
      ],
    );
  }

  Widget _buildFriendsList(String userId) {
    final friendRepo = ref.read(friendRepositoryProvider);

    return StreamBuilder<List<FriendModel>>(
      stream: friendRepo.streamFriends(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                const SizedBox(height: 12),
                Text(
                  'Error loading friends',
                  style: AppTheme.body(color: AppTheme.error),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        // Filter friends by search query
        var friends = snapshot.data!;
        if (_searchQuery.isNotEmpty) {
          friends = friends.where((friend) {
            return friend.displayName.toLowerCase().contains(_searchQuery) ||
                friend.friendEmail.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (friends.isEmpty && _searchQuery.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: AppTheme.textMedium),
                const SizedBox(height: 12),
                Text(
                  'No friends match "$_searchQuery"',
                  style: AppTheme.body(color: AppTheme.textMedium),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _buildFriendCardWithData(friend, userId);
          },
        );
      },
    );
  }

  Widget _buildFriendCardWithData(FriendModel friend, String userId) {
    final userRepo = ref.read(userRepositoryProvider);
    final markerRepo = ref.read(markerRepositoryProvider);

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        userRepo.getById(friend.friendEmail),
        markerRepo.getLocationSharingInfo(
          ownerEmail: friend.friendEmail,
          viewerEmail: userId,
        ),
      ]),
      builder: (context, snapshot) {
        final userData = snapshot.data?[0] as UserModel?;
        final sharingInfo = snapshot.data?[1] as LocationSharingInfo? ??
            const LocationSharingInfo.empty();

        return FriendCard(
          friend: friend,
          userData: userData,
          sharingInfo: sharingInfo,
          onViewLocations: () => _navigateToLocations(friend),
          onForageTogether: () => _showForageTogetherDialog(friend),
          onViewProfile: () => _navigateToProfile(userData, friend),
          onToggleTrustedForager: () => _toggleTrustedForager(userId, friend),
          onToggleEmergencyContact: () => _toggleEmergencyContact(userId, friend),
          onRemoveFriend: () => _showRemoveFriendDialog(userId, friend),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.textMedium.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No friends yet',
              style: AppTheme.title(size: 18, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to the Discover tab to find foragers near you, or send friend requests from the Requests tab.',
              textAlign: TextAlign.center,
              style: AppTheme.body(size: 14, color: AppTheme.textMedium),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLocations(FriendModel friend) {
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
  }

  Future<void> _navigateToProfile(UserModel? userData, FriendModel friend) async {
    if (userData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(user: userData, showBackButton: true),
        ),
      );
    } else {
      // Fetch user data if not available
      final userRepo = ref.read(userRepositoryProvider);
      final freshData = await userRepo.getById(friend.friendEmail);
      if (freshData != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(user: freshData, showBackButton: true),
          ),
        );
      }
    }
  }

  Future<void> _showForageTogetherDialog(FriendModel friend) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => NotifyEmergencyContactDialog(
        partnerUsername: friend.displayName,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Emergency contacts notified!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleTrustedForager(String userId, FriendModel friend) async {
    try {
      final friendRepo = ref.read(friendRepositoryProvider);
      final newStatus = !friend.closeFriend;
      await friendRepo.setCloseFriend(userId, friend.friendEmail, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? '${friend.displayName} is now a Trusted Forager! They can see your precise locations.'
                  : '${friend.displayName} removed from Trusted Foragers.',
            ),
            backgroundColor: newStatus ? AppTheme.success : AppTheme.info,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleEmergencyContact(String userId, FriendModel friend) async {
    try {
      final friendRepo = ref.read(friendRepositoryProvider);
      final newStatus = !friend.isEmergencyContact;
      await friendRepo.setEmergencyContact(userId, friend.friendEmail, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? '${friend.displayName} is now an Emergency Contact. They\'ll be notified when you plan foraging meetups.'
                  : '${friend.displayName} removed as Emergency Contact.',
            ),
            backgroundColor: newStatus ? AppTheme.warning : AppTheme.info,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showRemoveFriendDialog(String userId, FriendModel friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        title: Row(
          children: [
            Icon(Icons.person_remove, color: AppTheme.error),
            const SizedBox(width: 8),
            const Text('Remove Friend'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${friend.displayName} as a friend?\n\nYou will no longer see each other\'s shared locations.',
          style: AppTheme.body(size: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTheme.button(color: AppTheme.textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final friendRepo = ref.read(friendRepositoryProvider);
        await friendRepo.removeFriend(userId, friend.friendEmail);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${friend.displayName} removed from friends'),
              backgroundColor: AppTheme.info,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove friend: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }
}
