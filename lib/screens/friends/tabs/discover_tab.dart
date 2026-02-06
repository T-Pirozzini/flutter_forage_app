import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/services/geocoding_cache.dart';
import 'package:flutter_forager_app/screens/friends/components/send_forage_request_dialog.dart';
import 'package:flutter_forager_app/screens/friends/components/send_friend_request_dialog.dart';
import 'package:flutter_forager_app/screens/profile/user_profile_view_screen.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

/// Helper class to store user location info with coordinates
class _UserLocationInfo {
  final String address;
  final double latitude;
  final double longitude;

  _UserLocationInfo({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

/// Discover tab for finding nearby foragers who are open to connecting.
///
/// This tab is used within FriendsController and does NOT have its own AppBar.
///
/// Features:
/// - Search by username
/// - Filter by forage interests (mushrooms, berries, etc.)
/// - Shows users with openToForage = true
/// - "Let's Forage Together" button to send connection request
class DiscoverTab extends ConsumerStatefulWidget {
  const DiscoverTab({super.key});

  @override
  ConsumerState<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<DiscoverTab> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedInterests = {};
  List<UserModel> _foragers = [];
  bool _isLoading = true;
  Position? _userLocation;

  /// Cache of user locations by email - stores (address, lat, lng)
  final Map<String, _UserLocationInfo> _userLocations = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadForagers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      // Try to get device location for proximity sorting
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final hasPermission = await Geolocator.isLocationServiceEnabled();
      if (hasPermission) {
        final position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          setState(() => _userLocation = position);
        }
      }
    } catch (e) {
      // Silently fail - location is optional for discovery
      debugPrint('Location not available: $e');
    }
  }

  /// Get location info for a user.
  ///
  /// Priority:
  /// 1. Use primaryForageLocation from user profile (if set)
  /// 2. Fall back to most recent marker location
  /// 3. Auto-set primaryForageLocation from marker for future use
  Future<_UserLocationInfo?> _fetchUserLocation(UserModel user) async {
    try {
      // 1. Check if user has a primary forage location set
      if (user.hasPrimaryForageLocation) {
        return _UserLocationInfo(
          address: user.primaryForageLocation!,
          latitude: user.primaryForageLatitude!,
          longitude: user.primaryForgeLongitude!,
        );
      }

      // 2. Fall back to most recent marker
      final markerRepo = ref.read(markerRepositoryProvider);
      final markers = await markerRepo.getByUserId(user.email);

      if (markers.isEmpty) return null;

      // Sort by timestamp to get most recent
      markers.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final mostRecent = markers.first;

      // Use GeocodingCache to get a general location (city, country)
      final address = await GeocodingCache.getAddress(
        mostRecent.latitude,
        mostRecent.longitude,
      );

      // 3. Auto-set this as the user's primary location for future use
      // Only do this for the current user viewing, not for others
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email == user.email) {
        final userRepo = ref.read(userRepositoryProvider);
        await userRepo.setPrimaryForageLocation(
          userId: user.email,
          location: address,
          latitude: mostRecent.latitude,
          longitude: mostRecent.longitude,
        );
      }

      return _UserLocationInfo(
        address: address,
        latitude: mostRecent.latitude,
        longitude: mostRecent.longitude,
      );
    } catch (e) {
      debugPrint('Failed to fetch location for ${user.email}: $e');
      return null;
    }
  }

  /// Load locations for all foragers in the background
  Future<void> _loadUserLocations(List<UserModel> users) async {
    for (final user in users) {
      if (!_userLocations.containsKey(user.email)) {
        final locationInfo = await _fetchUserLocation(user);
        if (locationInfo != null && mounted) {
          setState(() {
            _userLocations[user.email] = locationInfo;
          });
        }
      }
    }
  }

  Future<void> _loadForagers() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email == null) return;

      final userRepo = ref.read(userRepositoryProvider);
      final friendRepo = ref.read(friendRepositoryProvider);

      // Get all users who are open to foraging
      final openToForageUsers = await userRepo.getUsersOpenToForage();

      // Get all friends (so they can plan forages even if not "open")
      final friends = await friendRepo.getFriends(currentUser!.email!);
      final friendEmails = friends.map((f) => f.friendEmail).toSet();

      // Track which emails we've already added
      final addedEmails = <String>{};
      final List<UserModel> filteredUsers = [];

      // First, add current user if they're open to foraging (for verification)
      for (final user in openToForageUsers) {
        if (user.email == currentUser.email) {
          filteredUsers.add(user);
          addedEmails.add(user.email);
          break;
        }
      }

      // Add friends (marked as isFriend) - they appear after "You"
      for (final friend in friends) {
        // Try to find this friend in openToForage list first
        final openUserIndex = openToForageUsers.indexWhere(
          (u) => u.email == friend.friendEmail,
        );

        if (openUserIndex >= 0) {
          // Friend is also open to foraging
          filteredUsers.add(openToForageUsers[openUserIndex].copyWith(isFriend: true));
        } else {
          // Friend is not open to foraging - fetch their user data
          final userData = await userRepo.getById(friend.friendEmail);
          if (userData != null) {
            filteredUsers.add(userData.copyWith(isFriend: true));
          }
        }
        addedEmails.add(friend.friendEmail);
      }

      // Add remaining open-to-forage users (not friends, not current user)
      for (final user in openToForageUsers) {
        if (!addedEmails.contains(user.email)) {
          final hasPendingRequest = await friendRepo.hasPendingRequest(
            currentUser.email!,
            user.email,
          );
          filteredUsers.add(user.copyWith(
            isFriend: false,
            hasPendingRequest: hasPendingRequest,
          ));
          addedEmails.add(user.email);
        }
      }

      setState(() {
        _foragers = filteredUsers;
        _isLoading = false;
      });

      // Load locations in background after showing the list
      _loadUserLocations(filteredUsers);
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
        return _selectedInterests
            .any((interest) => preferences.contains(interest.toLowerCase()));
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
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search foragers...',
              hintStyle: AppTheme.caption(color: AppTheme.textMedium),
              prefixIcon: Icon(Icons.search, color: AppTheme.textMedium),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: AppTheme.textMedium.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: AppTheme.textMedium.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.primary),
              ),
              filled: true,
              fillColor: AppTheme.surfaceLight,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          height: 44,
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
                      size: 11,
                      color: isSelected ? Colors.white : color,
                      weight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => _toggleInterest(type),
                  backgroundColor: color.withValues(alpha: 0.1),
                  selectedColor: color,
                  checkmarkColor: Colors.white,
                  visualDensity: VisualDensity.compact,
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
              Icon(Icons.nature_people, size: 14, color: AppTheme.textMedium),
              const SizedBox(width: 6),
              Text(
                '${_filteredForagers.length} foragers open to connect',
                style: AppTheme.caption(size: 12),
              ),
              const Spacer(),
              if (_selectedInterests.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() => _selectedInterests.clear());
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear filters',
                    style: AppTheme.caption(
                      size: 11,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(Icons.refresh, size: 20, color: AppTheme.primary),
                tooltip: 'Refresh',
                onPressed: _loadForagers,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),
        const Divider(height: 1),

        // Foragers list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredForagers.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadForagers,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredForagers.length,
                        itemBuilder: (context, index) {
                          return _buildForagerCard(_filteredForagers[index]);
                        },
                      ),
                    ),
        ),
      ],
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
                  : 'Check back later for foragers who are open to connecting.',
              style: AppTheme.body(size: 14, color: AppTheme.textMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadForagers,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForagerCard(UserModel user) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUser = user.email == currentUser?.email;
    final locationInfo = _userLocations[user.email];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
        side: isCurrentUser
            ? BorderSide(color: AppTheme.info, width: 2)
            : BorderSide.none,
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: AppTheme.borderRadiusMedium,
        onTap: () => _showForagerDetailDialog(user, locationInfo),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: isCurrentUser ? null : () => _viewUserProfile(user),
                    child: FutureBuilder<String>(
                      future: _getProfileImageUrl(user.profilePic),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return CircleAvatar(
                            radius: 22,
                            backgroundImage: NetworkImage(snapshot.data!),
                          );
                        }
                        return CircleAvatar(
                          radius: 22,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            user.username.isNotEmpty
                                ? user.username[0].toUpperCase()
                                : '?',
                            style: AppTheme.title(color: Colors.white, size: 16),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

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
                                style: AppTheme.title(size: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 6),
                              _buildYouBadge(),
                            ],
                            if (!isCurrentUser && user.isFriend) ...[
                              const SizedBox(width: 6),
                              _buildFriendBadge(),
                            ],
                          ],
                        ),
                        // Location (compact)
                        if (locationInfo != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: AppTheme.textMedium),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  locationInfo.address,
                                  style: AppTheme.caption(size: 11, color: AppTheme.textMedium),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_userLocation != null) ...[
                                const SizedBox(width: 4),
                                _buildDistanceBadge(locationInfo),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // View more indicator
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppTheme.textMedium.withValues(alpha: 0.5),
                  ),
                ],
              ),

              // Forage type chips (only forage types, compact)
              if (user.foragePreferences?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                _buildForageTypeChips(user.foragePreferences!),
              ],

              const SizedBox(height: 10),

              // Action button (or info text for current user)
              _buildActionButton(user, isCurrentUser),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceBadge(_UserLocationInfo locationInfo) {
    final distanceMeters = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      locationInfo.latitude,
      locationInfo.longitude,
    );

    String distanceText;
    if (distanceMeters < 1000) {
      distanceText = '${distanceMeters.round()}m';
    } else if (distanceMeters < 10000) {
      distanceText = '${(distanceMeters / 1000).toStringAsFixed(1)}km';
    } else {
      distanceText = '${(distanceMeters / 1000).round()}km';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        distanceText,
        style: AppTheme.caption(size: 9, color: AppTheme.success, weight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFriendBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Friend',
        style: AppTheme.caption(size: 9, color: AppTheme.success, weight: FontWeight.w600),
      ),
    );
  }

  /// Build compact forage type chips (only forage types, max 3 + "more")
  Widget _buildForageTypeChips(String preferences) {
    final prefs = preferences
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();

    if (prefs.isEmpty) return const SizedBox.shrink();

    // Only show forage types
    final forageTypes = ForageTypeUtils.allTypes.map((t) => t.toLowerCase()).toSet();
    final matchingTypes = prefs.where((p) => forageTypes.contains(p)).take(3).toList();
    final totalForageTypes = prefs.where((p) => forageTypes.contains(p)).length;
    final extraCount = totalForageTypes - matchingTypes.length;

    if (matchingTypes.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ...matchingTypes.map((type) {
                final color = ForageTypeUtils.getTypeColor(type);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _capitalizeFirst(type),
                    style: AppTheme.caption(size: 9, color: color, weight: FontWeight.w500),
                  ),
                );
              }),
              if (extraCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.textMedium.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+$extraCount more',
                    style: AppTheme.caption(size: 9, color: AppTheme.textMedium),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Show detailed dialog for a forager
  void _showForagerDetailDialog(UserModel user, _UserLocationInfo? locationInfo) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUser = user.email == currentUser?.email;
    final memberSince = user.createdAt.toDate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.textMedium.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Profile header
                Row(
                  children: [
                    GestureDetector(
                      onTap: isCurrentUser
                          ? null
                          : () {
                              Navigator.pop(context); // Close bottom sheet first
                              _viewUserProfile(user);
                            },
                      child: FutureBuilder<String>(
                        future: _getProfileImageUrl(user.profilePic),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            return CircleAvatar(
                              radius: 36,
                              backgroundImage: NetworkImage(snapshot.data!),
                            );
                          }
                          return CircleAvatar(
                            radius: 36,
                            backgroundColor: AppTheme.primary,
                            child: Text(
                              user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                              style: AppTheme.title(color: Colors.white, size: 24),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.username,
                                  style: AppTheme.heading(size: 20),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 8),
                                _buildYouBadge(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Member since ${DateFormat('MMMM yyyy').format(memberSince)}',
                            style: AppTheme.caption(color: AppTheme.textMedium),
                          ),
                          Text(
                            '${user.friends.length} friends',
                            style: AppTheme.caption(color: AppTheme.textMedium),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Location section
                if (locationInfo != null) ...[
                  _buildDetailSection(
                    icon: Icons.location_on,
                    title: 'Location',
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            locationInfo.address,
                            style: AppTheme.body(size: 14),
                          ),
                        ),
                        if (_userLocation != null)
                          _buildDistanceBadge(locationInfo),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Foraging interests section
                if (user.foragePreferences?.isNotEmpty ?? false) ...[
                  _buildDetailSection(
                    icon: Icons.eco,
                    title: 'Foraging Interests',
                    child: _buildAllPreferenceChips(user.foragePreferences!),
                  ),
                  const SizedBox(height: 16),
                ],

                // Bio section
                if (user.bio.isNotEmpty) ...[
                  _buildDetailSection(
                    icon: Icons.person,
                    title: 'About',
                    child: Text(
                      user.bio,
                      style: AppTheme.body(size: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Status badges
                if (!isCurrentUser) ...[
                  _buildDetailSection(
                    icon: Icons.badge,
                    title: 'Status',
                    child: Row(
                      children: [
                        if (user.isFriend)
                          _buildStatusChip('Friend', AppTheme.success, Icons.check)
                        else if (user.hasPendingRequest)
                          _buildStatusChip('Request Pending', AppTheme.warning, Icons.pending)
                        else
                          _buildStatusChip('Not Connected', AppTheme.textMedium, Icons.person_add),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Info text for current user
                if (isCurrentUser) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18, color: AppTheme.info),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This is how others see you in Discover. Edit your profile to update your info.',
                            style: AppTheme.caption(size: 12, color: AppTheme.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Action buttons
                  if (user.isFriend)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSendForageRequestDialog(user);
                        },
                        icon: const Icon(Icons.nature_people, size: 18),
                        label: const Text('Plan a Forage Together'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  else if (!user.hasPendingRequest)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSendFriendRequestDialog(user);
                        },
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text("Let's Forage Together"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTheme.title(size: 13, color: AppTheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: child,
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.caption(size: 12, color: color, weight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Build all preference chips for the detail dialog
  Widget _buildAllPreferenceChips(String preferences) {
    final prefs = preferences
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (prefs.isEmpty) return const SizedBox.shrink();

    final forageTypes = ForageTypeUtils.allTypes.map((t) => t.toLowerCase()).toSet();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: prefs.map((pref) {
        final isForageType = forageTypes.contains(pref.toLowerCase());
        final color = isForageType
            ? ForageTypeUtils.getTypeColor(pref.toLowerCase())
            : AppTheme.info;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            _capitalizeFirst(pref),
            style: AppTheme.caption(size: 12, color: color, weight: FontWeight.w500),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(UserModel user, bool isCurrentUser) {
    // Current user - show info text
    if (isCurrentUser) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility, size: 16, color: AppTheme.info),
            const SizedBox(width: 8),
            Text(
              'This is how others see you',
              style: AppTheme.caption(
                size: 12,
                color: AppTheme.info,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (user.isFriend) {
      // Already friends - show "Plan a Forage" button
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showSendForageRequestDialog(user),
          icon: const Icon(Icons.nature_people, size: 16),
          label: const Text('Plan a Forage'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.success,
            padding: const EdgeInsets.symmetric(vertical: 10),
            side: BorderSide(color: AppTheme.success),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    if (user.hasPendingRequest) {
      // Pending request - show disabled button
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.pending, size: 16),
          label: const Text('Request Pending'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    // Not friends - show "Let's Forage Together" button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showSendFriendRequestDialog(user),
        icon: const Icon(Icons.nature_people, size: 16),
        label: const Text("Let's Forage Together"),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildYouBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.info,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'You',
        style: AppTheme.caption(
          size: 9,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _viewUserProfile(UserModel user) {
    final currentUser = FirebaseAuth.instance.currentUser;
    // Don't navigate if it's the current user's own profile
    if (user.email == currentUser?.email) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileViewScreen(
          userEmail: user.email,
          displayName: user.username,
        ),
      ),
    );
  }

  Future<void> _showSendFriendRequestDialog(UserModel recipient) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => SendFriendRequestDialog(
        recipientUsername: recipient.username,
        recipientEmail: recipient.email,
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
        toEmail: recipient.email,
        message: result['message'] as String?,
      );

      // Update local state
      setState(() {
        _foragers = _foragers.map((user) {
          if (user.email == recipient.email) {
            return user.copyWith(hasPendingRequest: true);
          }
          return user;
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${recipient.username}!'),
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

  Future<void> _showSendForageRequestDialog(UserModel recipient) async {
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
        isFriend: recipient.isFriend, // Show planning UI for friends
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
