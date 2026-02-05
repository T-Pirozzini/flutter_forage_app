import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'components/send_forage_request_dialog.dart';

/// Screen for discovering nearby foragers who are open to foraging together.
///
/// Features:
/// - Search by username
/// - Filter by forage interests (mushrooms, berries, etc.)
/// - Shows users with openToForage = true
/// - "Let's Forage Together" button to send connection request
class NearbyForagersPage extends ConsumerStatefulWidget {
  const NearbyForagersPage({super.key});

  @override
  ConsumerState<NearbyForagersPage> createState() => _NearbyForagersPageState();
}

class _NearbyForagersPageState extends ConsumerState<NearbyForagersPage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedInterests = {};
  List<UserModel> _foragers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadForagers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadForagers() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email == null) return;

      final userRepo = ref.read(userRepositoryProvider);
      final friendRepo = ref.read(friendRepositoryProvider);

      // Get all users who are open to foraging
      final allUsers = await userRepo.getUsersOpenToForage();

      // Filter out current user and check friend status
      final List<UserModel> filteredUsers = [];
      for (final user in allUsers) {
        if (user.email != currentUser!.email) {
          // Check if already friends
          final isFriend = await friendRepo.areFriends(
            currentUser.email!,
            user.email,
          );
          filteredUsers.add(user.copyWith(isFriend: isFriend));
        }
      }

      setState(() {
        _foragers = filteredUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading foragers: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  List<UserModel> get _filteredForagers {
    var filtered = _foragers;

    // Filter by search query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.username.toLowerCase().contains(query) ||
            (user.foragePreferences?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filter by selected interests
    if (_selectedInterests.isNotEmpty) {
      filtered = filtered.where((user) {
        final preferences = user.foragePreferences?.toLowerCase() ?? '';
        return _selectedInterests.any((interest) =>
            preferences.contains(interest.toLowerCase()));
      }).toList();
    }

    return filtered;
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

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nearby Foragers',
          style: AppTheme.heading(size: 20, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _loadForagers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search foragers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Interest filter chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: ForageTypeUtils.allTypes.length,
              itemBuilder: (context, index) {
                final type = ForageTypeUtils.allTypes[index];
                final isSelected = _selectedInterests.contains(type);
                final color = ForageTypeUtils.getTypeColor(type);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      _capitalizeFirst(type),
                      style: AppTheme.caption(
                        size: 12,
                        color: isSelected ? Colors.white : color,
                        weight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => _toggleInterest(type),
                    backgroundColor: color.withValues(alpha: 0.1),
                    selectedColor: color,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: color.withValues(alpha: 0.3)),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Results info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.nature_people, size: 16, color: AppTheme.textMedium),
                const SizedBox(width: 6),
                Text(
                  '${_filteredForagers.length} foragers open to connect',
                  style: AppTheme.caption(size: 13),
                ),
                const Spacer(),
                if (_selectedInterests.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedInterests.clear());
                    },
                    child: Text(
                      'Clear filters',
                      style: AppTheme.caption(
                        size: 12,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // Foragers list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredForagers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredForagers.length,
                        itemBuilder: (context, index) {
                          return _buildForagerCard(_filteredForagers[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.nature_people,
              size: 64,
              color: AppTheme.textMedium.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No foragers found',
              style: AppTheme.title(size: 18, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedInterests.isNotEmpty
                  ? 'Try clearing your filters or searching with different terms.'
                  : 'Check back later for foragers in your area who are open to connecting.',
              style: AppTheme.body(size: 14, color: AppTheme.textMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForagerCard(UserModel user) {
    final memberSince = user.createdAt.toDate();
    final daysSinceMember = DateTime.now().difference(memberSince).inDays;
    final activityLevel = _getActivityLevel(daysSinceMember, user.friends.length);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                FutureBuilder<String>(
                  future: _getProfileImageUrl(user.profilePic),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(snapshot.data!),
                      );
                    }
                    return CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : '?',
                        style: AppTheme.title(color: Colors.white, size: 20),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 14),

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
                          const SizedBox(width: 8),
                          _buildActivityBadge(activityLevel),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (user.foragePreferences?.isNotEmpty ?? false)
                        Text(
                          user.foragePreferences!,
                          style: AppTheme.body(
                            size: 13,
                            color: AppTheme.textMedium,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Friend status indicator
                if (user.isFriend)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: AppTheme.success),
                        const SizedBox(width: 4),
                        Text(
                          'Friend',
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
            ),

            const SizedBox(height: 12),

            // Reputation row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
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

            const SizedBox(height: 14),

            // Action button
            if (!user.isFriend)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showSendRequestDialog(user),
                  icon: const Icon(Icons.nature_people, size: 18),
                  label: const Text("Let's Forage Together"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showSendRequestDialog(user),
                  icon: const Icon(Icons.nature_people, size: 18),
                  label: const Text('Plan a Forage'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppTheme.success),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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

  String _getActivityLevel(int daysSinceMember, int friendCount) {
    if (daysSinceMember < 7 || friendCount < 2) {
      return 'New';
    }
    if (daysSinceMember > 30 && friendCount > 5) {
      return 'Active';
    }
    return 'Regular';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _showSendRequestDialog(UserModel recipient) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == null) return;

    final userRepo = ref.read(userRepositoryProvider);
    final currentUserData = await userRepo.getById(currentUser!.email!);

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SendForageRequestDialog(
        recipientUsername: recipient.username,
        recipientEmail: recipient.email,
        senderUsername: currentUserData?.username ?? currentUser.email!,
        senderEmail: currentUser.email!,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Forage request sent to ${recipient.username}!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
