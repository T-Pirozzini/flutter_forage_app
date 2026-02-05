import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/providers/markers/marker_data.dart';
import 'package:flutter_forager_app/screens/friends/friends_controller.dart';
import 'package:flutter_forager_app/screens/my_foraging/my_foraging_page.dart';
import 'package:flutter_forager_app/screens/onboarding/onboarding_screen.dart';
import 'package:flutter_forager_app/screens/recipes/saved_recipes_page.dart';
import 'package:flutter_forager_app/screens/recipes/user_recipes_page.dart';
import 'package:flutter_forager_app/screens/profile/components/edit_profile_dialog.dart';
import 'package:flutter_forager_app/screens/profile/components/user_heading.dart';
import 'package:flutter_forager_app/screens/achievements/achievements_page.dart';
import 'package:flutter_forager_app/screens/leaderboard/leaderboard_page.dart';
import 'package:flutter_forager_app/shared/gamification/stats_card.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final UserModel user;
  final bool showBackButton;

  const ProfilePage({required this.user, this.showBackButton = false, Key? key})
      : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  // profile UI
  final double coverHeight = 200.0;
  final double profileHeight = 100.0;

  // background image options
  List<String> imageBackgroundOptions = [
    'backgroundProfileImage1.jpg',
    'backgroundProfileImage2.jpg',
    'backgroundProfileImage3.jpg',
    'backgroundProfileImage4.jpg',
    'backgroundProfileImage5.jpg',
    'backgroundProfileImage6.jpg',
  ];

  // Profile image options
  List<String> imageProfileOptions = [
    'profileImage1.jpg',
    'profileImage2.jpg',
    'profileImage3.jpg',
    'profileImage4.jpg',
    'profileImage5.jpg',
    'profileImage6.jpg',
    'profileImage7.jpg',
    'profileImage8.jpg',
    'profileImage9.jpg',
    'profileImage10.jpg',
  ];

  // initial values
  String selectedBackgroundOption = 'backgroundProfileImage1.jpg';
  String selectedProfileOption = 'profileImage1.jpg';
  String username = '';
  String bio = '';
  Timestamp createdAt = Timestamp.now();
  Timestamp lastActive = Timestamp.now();
  bool get _isCurrentUser => widget.user.email == currentUser.email;
  bool get _isFriend => widget.user.friends.contains(currentUser.email);

  // Get the user whose profile we're viewing
  String get _profileUserId =>
      _isCurrentUser ? currentUser.email! : widget.user.email;

  @override
  void initState() {
    super.initState();
    loadUserProfileImages();
  }

  void loadUserProfileImages() async {
    final userRepo = ref.read(userRepositoryProvider);
    final user = await userRepo.getById(_profileUserId);

    if (user != null) {
      setState(() {
        selectedBackgroundOption = user.profileBackground.isNotEmpty
            ? user.profileBackground
            : 'backgroundProfileImage1.jpg';
        selectedProfileOption =
            user.profilePic.isNotEmpty ? user.profilePic : 'profileImage1.jpg';
        username = user.username;
        bio = user.bio;
        createdAt = user.createdAt;
        lastActive = user.lastActive;
      });
    }
  }

  Future<void> showProfileEditDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal during save
      builder: (context) => EditProfileDialog(
        username: username,
        bio: bio,
        selectedProfileOption: selectedProfileOption,
        selectedBackgroundOption: selectedBackgroundOption,
        imageProfileOptions: imageProfileOptions,
        imageBackgroundOptions: imageBackgroundOptions,
        onSave:
            (newUsername, newBio, newProfileImage, newBackgroundImage) async {
          setState(() {
            username = newUsername.trim().isNotEmpty ? newUsername : username;
            bio = newBio.trim().isNotEmpty ? newBio : bio;
            selectedProfileOption = newProfileImage;
            selectedBackgroundOption = newBackgroundImage;
          });

          final userRepo = ref.read(userRepositoryProvider);
          await userRepo.update(currentUser.email!, {
            'username': username,
            'bio': bio,
            'profilePic': selectedProfileOption,
            'profileBackground': selectedBackgroundOption,
          });
        },
      ),
    );
  }

  // back to main page
  void goHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final userMarkers = ref.watch(userMarkersProvider(_profileUserId));
    final communityMarkers =
        ref.watch(communityMarkersProvider(_profileUserId));

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: widget.showBackButton
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: AppTheme.textWhite),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  _isCurrentUser
                      ? 'My Profile'
                      : '${widget.user.username}\'s Profile',
                  style: AppTheme.heading(size: 20, color: AppTheme.textWhite),
                ),
                centerTitle: true,
                // Only show edit button for current user
                actions: _isCurrentUser
                    ? [
                        IconButton(
                          icon: Icon(Icons.edit, color: AppTheme.textWhite),
                          onPressed: showProfileEditDialog,
                        ),
                      ]
                    : null,
              )
            : null,
        // Show floating action button only when there's no AppBar
        floatingActionButton: !widget.showBackButton && _isCurrentUser
            ? FloatingActionButton(
                heroTag: 'profileEditButton',
                backgroundColor: AppTheme.secondary,
                onPressed: showProfileEditDialog,
                child: Icon(Icons.edit, color: AppTheme.textWhite),
                mini: true,
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
        body: StreamBuilder<UserModel?>(
          stream: ref.read(userRepositoryProvider).streamById(_profileUserId),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final userData = snapshot.data!;
              // Update local variables for UI
              final currentBackground = userData.profileBackground.isNotEmpty
                  ? userData.profileBackground
                  : 'backgroundProfileImage1.jpg';
              final currentProfile = userData.profilePic.isNotEmpty
                  ? userData.profilePic
                  : 'profileImage1.jpg';
              final currentUsername = userData.username;
              final currentBio = userData.bio;

              // Also update class-level state for edit dialog
              selectedBackgroundOption = currentBackground;
              selectedProfileOption = currentProfile;
              username = currentUsername;
              bio = currentBio;

              return Column(
                children: [
                  // Compact header
                  UserHeading(
                    username: currentUsername,
                    selectedBackgroundOption: currentBackground,
                    selectedProfileOption: currentProfile,
                    createdAt: userData.createdAt,
                    lastActive: userData.lastActive,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        // 1. STAT BUTTONS - Most important, right at top
                        FutureBuilder<int>(
                          future: ref
                              .read(recipeRepositoryProvider)
                              .getRecipeCountByUser(_profileUserId),
                          builder: (context, recipeSnapshot) {
                            String recipeCount = '0';
                            if (recipeSnapshot.connectionState ==
                                ConnectionState.done) {
                              if (recipeSnapshot.hasData) {
                                recipeCount = recipeSnapshot.data.toString();
                              }
                            }
                            // Calculate combined count for My Foraging
                            final locationsCount =
                                userMarkers.value?.length ?? 0;
                            final bookmarksCount =
                                communityMarkers.value?.length ?? 0;
                            final totalForaging =
                                locationsCount + bookmarksCount;

                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              childAspectRatio: 0.95,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                              padding: EdgeInsets.zero,
                              children: [
                                _buildStatCard(
                                  context,
                                  icon: Icons.forest,
                                  title: 'My Foraging',
                                  value: totalForaging.toString(),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MyForagingPage(),
                                    ),
                                  ),
                                  enabled: _isCurrentUser,
                                ),
                                _buildStatCard(
                                  context,
                                  icon: Icons.menu_book,
                                  title: 'Recipes',
                                  value: recipeCount,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const UserRecipesPage(),
                                    ),
                                  ),
                                  enabled: _isCurrentUser ||
                                      _isFriend ||
                                      recipeCount != '0',
                                ),
                                _buildStatCard(
                                  context,
                                  icon: Icons.people,
                                  title: 'Friends',
                                  value: widget.user.friends.length.toString(),
                                  onTap: () {
                                    if (_isCurrentUser) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const FriendsController(
                                                  currentTab: 0),
                                        ),
                                      );
                                    }
                                  },
                                  enabled: _isCurrentUser,
                                ),
                              ],
                            );
                          },
                        ),
                        // 2. ABOUT ME - Compact card
                        if (currentBio.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildCompactAboutMe(currentBio),
                          ),

                        // 3. GAMIFICATION STATS - Level, XP, Streak
                        if (_isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: StatsCard(
                              user: userData,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AchievementsPage(),
                                ),
                              ),
                            ),
                          ),

                        // 3.5. OPEN TO FORAGING TOGETHER TOGGLE
                        if (_isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildOpenToForagingCard(userData),
                          ),

                        // 4. SAVED RECIPES BUTTON
                        if (_isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildCompactButton(
                              icon: Icons.bookmark,
                              label: 'Saved Recipes',
                              color: AppTheme.accent,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SavedRecipesPage(),
                                ),
                              ),
                            ),
                          ),

                        // 5. ACHIEVEMENTS & LEADERBOARD BUTTONS
                        if (_isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildCompactButton(
                                    icon: Icons.workspace_premium,
                                    label: 'Achievements',
                                    color: AppTheme.xp,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AchievementsPage(),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildCompactButton(
                                    icon: Icons.leaderboard,
                                    label: 'Leaderboard',
                                    color: AppTheme.secondary,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LeaderboardPage(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 6. FRIEND REQUESTS (if any)
                        if (_isCurrentUser &&
                            widget.user.friendRequests.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildFriendRequestsButton(),
                          ),

                        // 7. TUTORIAL BUTTON - Small, at bottom
                        if (_isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton.icon(
                              icon: Icon(Icons.help_outline,
                                  size: 16, color: AppTheme.textMedium),
                              label: Text(
                                'App Tutorial',
                                style: AppTheme.caption(
                                    size: 12, color: AppTheme.textMedium),
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OnboardingScreen(isTutorial: true),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(
                            height: 80), // Bottom padding for nav bar
                      ],
                    ),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading profile data',
                  style: TextStyle(color: Colors.red),
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Card(
      elevation: enabled ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      color: enabled ? Colors.white : Colors.grey[100],
      child: InkWell(
        borderRadius: AppTheme.borderRadiusMedium,
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadiusMedium,
            border: enabled
                ? Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    width: 1,
                  )
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: enabled ? AppTheme.primary : Colors.grey,
                ),
                const SizedBox(height: AppTheme.space8),
                AutoSizeText(
                  value,
                  minFontSize: 8,
                  maxLines: 1,
                  style: AppTheme.stats(
                    size: 20,
                    color: enabled ? AppTheme.primary : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                AutoSizeText(
                  title,
                  minFontSize: 8,
                  maxLines: 1,
                  style: AppTheme.caption(
                    size: 11,
                    color: enabled ? AppTheme.textMedium : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAboutMe(String bio) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.rotate(
              angle: 3.14159, // Opening quote (flipped)
              child: Icon(Icons.format_quote,
                  size: 12, color: AppTheme.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                bio,
                style: AppTheme.body(size: 12, color: AppTheme.textDark),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.format_quote,
                size: 12, color: AppTheme.primary.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusSmall,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.caption(
                  size: 12,
                  color: color,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendRequestsButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.borderRadiusSmall,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FriendsController(currentTab: 1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add, size: 18, color: AppTheme.textWhite),
                const SizedBox(width: 8),
                Text(
                  'Friend Requests (${widget.user.friendRequests.length})',
                  style: AppTheme.caption(
                    size: 13,
                    color: AppTheme.textWhite,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenToForagingCard(UserModel userData) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
        side: userData.openToForage
            ? BorderSide(color: AppTheme.success, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with toggle
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: userData.openToForage
                        ? AppTheme.success.withValues(alpha: 0.15)
                        : AppTheme.textMedium.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.hiking,
                    size: 20,
                    color: userData.openToForage
                        ? AppTheme.success
                        : AppTheme.textMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Open to Foraging Together',
                        style: AppTheme.title(size: 14),
                      ),
                      Text(
                        userData.openToForage
                            ? 'Others can see you\'re open to meetups'
                            : 'Toggle to show others you\'re available',
                        style: AppTheme.caption(size: 11),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: userData.openToForage,
                  activeTrackColor: AppTheme.success.withValues(alpha: 0.5),
                  activeThumbColor: AppTheme.success,
                  onChanged: (value) => _toggleOpenToForage(value),
                ),
              ],
            ),
            // Preferences field (shown when enabled)
            if (userData.openToForage) ...[
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(
                    text: userData.foragePreferences ?? ''),
                decoration: InputDecoration(
                  hintText: 'e.g., Weekends, mushrooms, beginner-friendly',
                  hintStyle: AppTheme.caption(size: 12, color: AppTheme.textLight),
                  labelText: 'Your foraging preferences',
                  labelStyle: AppTheme.caption(size: 12),
                  filled: true,
                  fillColor: AppTheme.backgroundLight,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.save, size: 20, color: AppTheme.primary),
                    onPressed: () {
                      // Save will happen on unfocus or explicit save
                    },
                  ),
                ),
                style: AppTheme.body(size: 13),
                maxLines: 2,
                onChanged: (value) {
                  // Debounced save
                  _saveForagePreferences(value);
                },
              ),
              const SizedBox(height: 12),
              // Safety reminder
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security, size: 16, color: AppTheme.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Safety tip: Always meet in public first (trailhead, parking lot). Tell someone where you\'re going.',
                        style: AppTheme.caption(
                          size: 11,
                          color: AppTheme.textDark,
                        ),
                      ),
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

  Future<void> _toggleOpenToForage(bool value) async {
    try {
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.update(currentUser.email!, {
        'openToForage': value,
      });

      if (mounted && value) {
        // Show safety dialog when enabling
        _showForagingSafetyDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating preference: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveForagePreferences(String preferences) async {
    try {
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.update(currentUser.email!, {
        'foragePreferences': preferences.trim().isEmpty ? null : preferences.trim(),
      });
    } catch (e) {
      // Silent fail for preferences - not critical
      debugPrint('Error saving forage preferences: $e');
    }
  }

  void _showForagingSafetyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        title: Row(
          children: [
            Icon(Icons.security, color: AppTheme.warning),
            const SizedBox(width: 8),
            Text('Stay Safe While Foraging', style: AppTheme.title(size: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'re now visible to other foragers looking for partners. Remember these safety tips:',
              style: AppTheme.body(size: 14),
            ),
            const SizedBox(height: 16),
            _buildSafetyTip(Icons.location_on, 'Meet in public first (trailhead, parking lot)'),
            _buildSafetyTip(Icons.people, 'Tell someone where you\'re going'),
            _buildSafetyTip(Icons.group, 'Forage in groups when possible'),
            _buildSafetyTip(Icons.psychology, 'Trust your instincts'),
            _buildSafetyTip(Icons.share_location, 'Share your location with an emergency contact'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!', style: AppTheme.button(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTheme.caption(size: 13)),
          ),
        ],
      ),
    );
  }
}
