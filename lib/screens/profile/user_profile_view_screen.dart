import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_locations_page.dart';
import 'package:flutter_forager_app/shared/gamification/stats_card.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Screen to view another user's profile when tapping on their avatar.
///
/// Shows:
/// - Profile header with avatar, username, bio
/// - Stats card (level, XP, streak)
/// - Open to foraging info with preferences
/// - Friend count, member since
/// - Action buttons (Add Friend, View Locations, Follow)
class UserProfileViewScreen extends ConsumerStatefulWidget {
  final String userEmail;
  final String? displayName;

  const UserProfileViewScreen({
    super.key,
    required this.userEmail,
    this.displayName,
  });

  @override
  ConsumerState<UserProfileViewScreen> createState() =>
      _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends ConsumerState<UserProfileViewScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  bool _isFriend = false;
  bool _hasPendingRequest = false;
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRelationship();
  }

  Future<void> _checkRelationship() async {
    try {
      final friendRepo = ref.read(friendRepositoryProvider);
      final followingRepo = ref.read(followingRepositoryProvider);

      final isFriend = await friendRepo.areFriends(
        _currentUser.email!,
        widget.userEmail,
      );

      final hasPending = await friendRepo.hasPendingRequest(
        _currentUser.email!,
        widget.userEmail,
      );

      final isFollowing = await followingRepo.isFollowing(
        _currentUser.email!,
        widget.userEmail,
      );

      if (mounted) {
        setState(() {
          _isFriend = isFriend;
          _hasPendingRequest = hasPending;
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  Future<void> _sendFriendRequest(UserModel user) async {
    try {
      final friendRepo = ref.read(friendRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final currentUserData = await userRepo.getById(_currentUser.email!);

      await friendRepo.sendRequest(
        fromEmail: _currentUser.email!,
        fromDisplayName: currentUserData?.username ?? _currentUser.email!,
        fromPhotoUrl: currentUserData?.profilePic,
        toEmail: widget.userEmail,
        toDisplayName: user.username,
      );

      if (mounted) {
        setState(() => _hasPendingRequest = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${user.username}'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending request: $e')),
        );
      }
    }
  }

  Future<void> _toggleFollow(UserModel user) async {
    try {
      final followingRepo = ref.read(followingRepositoryProvider);
      final newState = await followingRepo.toggleFollow(
        userId: _currentUser.email!,
        targetEmail: widget.userEmail,
        targetDisplayName: user.username,
      );

      if (mounted) {
        setState(() => _isFollowing = newState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newState
                  ? 'Now following ${user.username}'
                  : 'Unfollowed ${user.username}',
            ),
            backgroundColor: newState ? AppTheme.success : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _viewLocations(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForageLocations(
          userId: widget.userEmail,
          userName: user.username,
          userLocations: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show this screen for the current user
    if (widget.userEmail == _currentUser.email) {
      Navigator.pop(context);
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      appBar: AppBar(
        title: Text(
          widget.displayName ?? 'User Profile',
          style: AppTheme.title(size: 18, color: AppTheme.textWhite),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textWhite,
        elevation: 0,
      ),
      body: StreamBuilder<UserModel?>(
        stream: ref.read(userRepositoryProvider).streamById(widget.userEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: AppTheme.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'User not found',
                    style:
                        AppTheme.heading(size: 18, color: AppTheme.textMedium),
                  ),
                ],
              ),
            );
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(user),
                const SizedBox(height: 16),

                // Action Buttons
                _buildActionButtons(user),
                const SizedBox(height: 16),

                // Stats Card (Level, XP, Streak)
                StatsCard(user: user),
                const SizedBox(height: 16),

                // Bio Section
                if (user.bio.isNotEmpty) ...[
                  _buildBioSection(user),
                  const SizedBox(height: 16),
                ],

                // Open to Foraging Section
                if (user.openToForage) ...[
                  _buildOpenToForagingSection(user),
                  const SizedBox(height: 16),
                ],

                // Member Info Section
                _buildMemberInfoSection(user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.accent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          FutureBuilder<String>(
            future: _getProfileImageUrl(user.profilePic),
            builder: (context, snapshot) {
              return CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primary,
                backgroundImage: snapshot.hasData && snapshot.data!.isNotEmpty
                    ? NetworkImage(snapshot.data!)
                    : null,
                child: snapshot.hasData && snapshot.data!.isNotEmpty
                    ? null
                    : Text(
                        user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : '?',
                        style: AppTheme.title(color: Colors.white, size: 32),
                      ),
              );
            },
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: AppTheme.heading(size: 22, color: AppTheme.textWhite),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.email.split('@').first}',
                  style: AppTheme.caption(size: 14, color: AppTheme.textLight),
                ),
                const SizedBox(height: 8),
                // Quick stats row
                Row(
                  children: [
                    _buildQuickStat(Icons.people, '${user.friends.length}'),
                    const SizedBox(width: 16),
                    _buildQuickStat(Icons.star, 'Lv ${user.level}'),
                    if (user.openToForage) ...[
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hiking,
                                size: 12, color: AppTheme.success),
                            const SizedBox(width: 4),
                            Text(
                              'Open',
                              style: AppTheme.caption(
                                size: 11,
                                color: AppTheme.success,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textLight),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTheme.caption(size: 12, color: AppTheme.textLight),
        ),
      ],
    );
  }

  Widget _buildActionButtons(UserModel user) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        // Friend/Request Button
        Expanded(
          child: _isFriend
              ? OutlinedButton.icon(
                  onPressed: () => _viewLocations(user),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Friends'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.success,
                    side: BorderSide(color: AppTheme.success),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                )
              : _hasPendingRequest
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.hourglass_top, size: 18),
                      label: const Text('Pending'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textMedium,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _sendFriendRequest(user),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add Friend'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
        ),
        const SizedBox(width: 12),
        // Follow Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _toggleFollow(user),
            icon: Icon(
              _isFollowing ? Icons.notifications_active : Icons.notifications,
              size: 18,
            ),
            label: Text(_isFollowing ? 'Following' : 'Follow'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  _isFollowing ? AppTheme.accent : AppTheme.primary,
              side: BorderSide(
                color: _isFollowing ? AppTheme.accent : AppTheme.primary,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'About',
                style: AppTheme.title(size: 14, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user.bio,
            style: AppTheme.body(size: 14, color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenToForagingSection(UserModel user) {
    final preferences = user.foragePreferences ?? '';
    final prefList = preferences
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.success.withValues(alpha: 0.15),
            AppTheme.success.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hiking, size: 20, color: AppTheme.success),
              const SizedBox(width: 8),
              Text(
                'Open to Foraging Together',
                style: AppTheme.title(size: 14, color: AppTheme.success),
              ),
            ],
          ),
          if (prefList.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: prefList.map((pref) {
                final color = _getPreferenceColor(pref);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _capitalizeFirst(pref),
                    style: AppTheme.caption(
                      size: 11,
                      color: color,
                      weight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (user.primaryForageLocation != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: AppTheme.textMedium),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    user.primaryForageLocation!,
                    style:
                        AppTheme.caption(size: 12, color: AppTheme.textMedium),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getPreferenceColor(String pref) {
    final lowerPref = pref.toLowerCase();
    // Check if it's a forage type
    for (final type in ForageTypeUtils.allTypes) {
      if (lowerPref == type.toLowerCase()) {
        return ForageTypeUtils.getTypeColor(type);
      }
    }
    // Availability tags
    if (['weekends', 'weekdays', 'mornings', 'evenings'].contains(lowerPref)) {
      return AppTheme.info;
    }
    // Skill tags
    if ([
      'beginner-friendly',
      'experienced',
      'willing to teach',
      'looking to learn'
    ].contains(lowerPref)) {
      return AppTheme.xp;
    }
    return AppTheme.primary;
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text.split('-').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join('-');
  }

  Widget _buildMemberInfoSection(UserModel user) {
    final memberSince = user.createdAt.toDate();
    final lastActive = user.lastActive.toDate();
    final now = DateTime.now();
    final lastActiveDiff = now.difference(lastActive);

    String lastActiveText;
    if (lastActiveDiff.inMinutes < 5) {
      lastActiveText = 'Active now';
    } else if (lastActiveDiff.inHours < 1) {
      lastActiveText = 'Active ${lastActiveDiff.inMinutes}m ago';
    } else if (lastActiveDiff.inHours < 24) {
      lastActiveText = 'Active ${lastActiveDiff.inHours}h ago';
    } else if (lastActiveDiff.inDays < 7) {
      lastActiveText = 'Active ${lastActiveDiff.inDays}d ago';
    } else {
      lastActiveText = 'Last active ${DateFormat('MMM d').format(lastActive)}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today,
            'Member since',
            DateFormat('MMMM yyyy').format(memberSince),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.access_time,
            'Activity',
            lastActiveText,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.people,
            'Friends',
            '${user.friends.length}',
          ),
          if (user.currentStreak > 0) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.local_fire_department,
              'Current streak',
              '${user.currentStreak} days',
              valueColor: AppTheme.accent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMedium),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTheme.caption(size: 13, color: AppTheme.textMedium),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTheme.body(
            size: 13,
            color: valueColor ?? AppTheme.textDark,
            weight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
