import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/friend_request.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/friends/components/send_friend_request_dialog.dart';
import 'package:flutter_forager_app/screens/profile/profile_page.dart';
import 'package:flutter_forager_app/shared/gamification/gamification_helper.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum RequestViewMode { received, sent }

/// Requests tab showing incoming and outgoing friend requests.
///
/// This tab is used within FriendsController and does NOT have its own AppBar.
/// Uses a SegmentedButton to toggle between Received and Sent requests.
class RequestsTab extends ConsumerStatefulWidget {
  const RequestsTab({super.key});

  @override
  ConsumerState<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<RequestsTab> {
  RequestViewMode _viewMode = RequestViewMode.received;
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _getProfileImageUrl(String imageName) async {
    if (imageName.isEmpty) return '';
    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref('profile_images/$imageName');
      return await ref.getDownloadURL();
    } catch (e) {
      return '';
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

    setState(() => _isSearching = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final userRepo = ref.read(userRepositoryProvider);
      final friendRepo = ref.read(friendRepositoryProvider);

      final allUsers = await userRepo.searchByUsername(query);

      final List<UserModel> results = [];
      for (final user in allUsers) {
        if (user.email != currentUser.email) {
          final isFriend = await friendRepo.areFriends(currentUser.email!, user.email);
          final hasPendingRequest =
              await friendRepo.hasPendingRequest(currentUser.email!, user.email);
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
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == null) {
      return const Center(child: Text('Please log in'));
    }

    return Column(
      children: [
        // Search bar to find users
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users to add...',
              hintStyle: AppTheme.caption(color: AppTheme.textMedium),
              prefixIcon: Icon(Icons.person_search, color: AppTheme.textMedium),
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

        // Show search results or request views
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isNotEmpty
                  ? _buildSearchResults(currentUser!.email!)
                  : _buildRequestsView(currentUser!.email!),
        ),
      ],
    );
  }

  Widget _buildSearchResults(String currentUserEmail) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildSearchResultCard(user, currentUserEmail);
      },
    );
  }

  Widget _buildSearchResultCard(UserModel user, String currentUserEmail) {
    final memberSince = user.createdAt.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusMedium,
        onTap: user.isFriend
            ? () => _navigateToProfile(user)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
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
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
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
                            style: AppTheme.title(size: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.openToForage) ...[
                          const SizedBox(width: 6),
                          _buildBadge('Open to Forage', AppTheme.success),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${DateFormat('MMM yyyy').format(memberSince)} • ${user.friends.length} friends',
                      style: AppTheme.caption(size: 11),
                    ),
                  ],
                ),
              ),
              // Action button
              _buildSearchActionButton(user, currentUserEmail),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchActionButton(UserModel user, String currentUserEmail) {
    if (user.isFriend) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, color: AppTheme.success, size: 20),
      );
    }

    if (user.hasPendingRequest) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.pending, color: AppTheme.warning, size: 20),
      );
    }

    return IconButton(
      icon: Icon(Icons.person_add, color: AppTheme.primary),
      onPressed: () => _sendFriendRequest(user.email, user.username),
    );
  }

  Widget _buildRequestsView(String userId) {
    return Column(
      children: [
        // Segmented button to toggle view mode
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SegmentedButton<RequestViewMode>(
            segments: [
              ButtonSegment(
                value: RequestViewMode.received,
                label: const Text('Received'),
                icon: const Icon(Icons.inbox, size: 18),
              ),
              ButtonSegment(
                value: RequestViewMode.sent,
                label: const Text('Sent'),
                icon: const Icon(Icons.outbox, size: 18),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (selection) {
              setState(() => _viewMode = selection.first);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primary;
                }
                return AppTheme.surfaceLight;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppTheme.textDark;
              }),
            ),
          ),
        ),

        // Request list
        Expanded(
          child: _viewMode == RequestViewMode.received
              ? _buildReceivedRequests(userId)
              : _buildSentRequests(userId),
        ),
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
          return _buildEmptyState(
            icon: Icons.inbox,
            title: 'No pending requests',
            subtitle: 'When someone sends you a friend request, it will appear here.',
          );
        }

        final requests = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildReceivedRequestCard(request, userId);
          },
        );
      },
    );
  }

  Widget _buildReceivedRequestCard(FriendRequestModel request, String userId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                FutureBuilder<String>(
                  future: _getProfileImageUrl(request.fromPhotoUrl ?? ''),
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
                        request.fromDisplayName.isNotEmpty
                            ? request.fromDisplayName[0].toUpperCase()
                            : '?',
                        style: AppTheme.title(color: Colors.white),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fromDisplayName,
                        style: AppTheme.title(size: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.fromEmail,
                        style: AppTheme.caption(size: 11),
                      ),
                    ],
                  ),
                ),
                // Accept/Decline buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: AppTheme.success, size: 20),
                      ),
                      tooltip: 'Accept',
                      onPressed: () => _handleRequest(userId, request, true),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: AppTheme.error, size: 20),
                      ),
                      tooltip: 'Decline',
                      onPressed: () => _handleRequest(userId, request, false),
                    ),
                  ],
                ),
              ],
            ),
            // Message if present
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.message, size: 12, color: AppTheme.info),
                        const SizedBox(width: 4),
                        Text(
                          'Message:',
                          style: AppTheme.caption(size: 10, color: AppTheme.info),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.message!,
                      style: AppTheme.body(size: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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
          return _buildEmptyState(
            icon: Icons.outbox,
            title: 'No sent requests',
            subtitle: 'Search for users above to send friend requests.',
          );
        }

        final requests = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildSentRequestCard(request, userId);
          },
        );
      },
    );
  }

  Widget _buildSentRequestCard(FriendRequestModel request, String userId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Text(
            request.toDisplayName.isNotEmpty
                ? request.toDisplayName[0].toUpperCase()
                : request.toEmail[0].toUpperCase(),
            style: AppTheme.title(color: Colors.white),
          ),
        ),
        title: Text(
          request.toDisplayName.isNotEmpty ? request.toDisplayName : request.toEmail,
          style: AppTheme.title(size: 15),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                request.status.name[0].toUpperCase() + request.status.name.substring(1),
                style: AppTheme.caption(size: 10, color: AppTheme.warning),
              ),
            ),
          ],
        ),
        trailing: request.isPending
            ? IconButton(
                icon: Icon(Icons.cancel, color: AppTheme.error),
                tooltip: 'Cancel request',
                onPressed: () => _cancelRequest(userId, request.toEmail),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.textMedium.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.title(size: 16, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTheme.caption(size: 13, color: AppTheme.textMedium),
            ),
          ],
        ),
      ),
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
        style: AppTheme.caption(size: 9, weight: FontWeight.w600, color: color),
      ),
    );
  }

  void _navigateToProfile(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(user: user, showBackButton: true),
      ),
    );
  }

  Future<void> _sendFriendRequest(String recipientEmail, String recipientUsername) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => SendFriendRequestDialog(
        recipientUsername: recipientUsername,
        recipientEmail: recipientEmail,
      ),
    );

    if (result == null || result['send'] != true) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final friendRepo = ref.read(friendRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

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

  Future<void> _handleRequest(
      String userId, FriendRequestModel request, bool accept) async {
    try {
      final friendRepo = ref.read(friendRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      if (accept) {
        final currentUserData = await userRepo.getById(userId);

        await friendRepo.acceptRequest(
          userId: userId,
          requestId: request.id,
          userDisplayName: currentUserData?.username ?? userId,
          userPhotoUrl: currentUserData?.profilePic,
        );

        if (mounted) {
          await GamificationHelper.awardFriendAdded(
            context: context,
            ref: ref,
            userId: userId,
          );
        }
      } else {
        await friendRepo.declineRequest(userId, request.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Friend request declined'),
              backgroundColor: AppTheme.info,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to handle request: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelRequest(String userId, String recipientEmail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this friend request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(color: AppTheme.error)),
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
            SnackBar(
              content: const Text('Request cancelled'),
              backgroundColor: AppTheme.info,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel request: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }
}
