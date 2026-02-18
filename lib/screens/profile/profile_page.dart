import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/data/services/geocoding_cache.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_forager_app/providers/markers/marker_data.dart';
import 'package:flutter_forager_app/screens/friends/friends_controller.dart';
import 'package:flutter_forager_app/screens/my_foraging/my_foraging_page.dart';
import 'package:flutter_forager_app/screens/onboarding/onboarding_screen.dart';
import 'package:flutter_forager_app/screens/recipes/user_recipes_page.dart';
import 'package:flutter_forager_app/screens/profile/components/edit_profile_dialog.dart';
import 'package:flutter_forager_app/screens/profile/components/user_heading.dart';
import 'package:flutter_forager_app/screens/achievements/achievements_page.dart';
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withValues(alpha: 0.85),
          ],
        ),
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
                              childAspectRatio: 0.82,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
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

                        // 3.25. APP TUTORIAL CARD
                        if (_isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildTutorialCard(),
                          ),

                        // 3.5. OPEN TO FORAGING TOGETHER TOGGLE
                        if (_isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildOpenToForagingCard(userData),
                          ),

                        // 3.6. LEADERBOARD VISIBILITY TOGGLE
                        if (_isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildLeaderboardVisibilityCard(userData),
                          ),

                        // 4. FRIEND REQUESTS (if any)
                        if (_isCurrentUser &&
                            widget.user.friendRequests.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildFriendRequestsButton(),
                          ),

                        const SizedBox(
                            height: 160), // Bottom padding for nav bar
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
    // Define unique colors for each card type
    Color accentColor;
    Color gradientStart;
    Color gradientEnd;

    switch (title) {
      case 'My Foraging':
        accentColor = AppTheme.success;
        gradientStart = const Color(0xFF2E7D32);
        gradientEnd = const Color(0xFF66BB6A);
        break;
      case 'Recipes':
        accentColor = AppTheme.accent;
        gradientStart = const Color(0xFFE65100);
        gradientEnd = const Color(0xFFFF9800);
        break;
      case 'Friends':
        accentColor = AppTheme.info;
        gradientStart = const Color(0xFF1565C0);
        gradientEnd = const Color(0xFF42A5F5);
        break;
      default:
        accentColor = AppTheme.primary;
        gradientStart = AppTheme.primary;
        gradientEnd = AppTheme.primaryLight;
    }

    if (!enabled) {
      accentColor = Colors.grey;
      gradientStart = Colors.grey.shade400;
      gradientEnd = Colors.grey.shade300;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTheme.borderRadiusMedium,
        onTap: enabled ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadiusMedium,
            color: Colors.white,
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with gradient background circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        gradientStart.withValues(alpha: 0.2),
                        gradientEnd.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Value with gradient text effect
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: enabled
                        ? [gradientStart, gradientEnd]
                        : [Colors.grey, Colors.grey],
                  ).createShader(bounds),
                  child: AutoSizeText(
                    value,
                    minFontSize: 12,
                    maxLines: 1,
                    style: AppTheme.stats(
                      size: 22,
                      color: Colors.white,
                      weight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Title
                AutoSizeText(
                  title,
                  minFontSize: 8,
                  maxLines: 1,
                  style: AppTheme.caption(
                    size: 11,
                    color: enabled ? AppTheme.textMedium : Colors.grey,
                    weight: FontWeight.w500,
                  ),
                ),
                // Tap hint arrow
                if (enabled) ...[
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: accentColor.withValues(alpha: 0.5),
                  ),
                ],
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

  Widget _buildTutorialCard() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OnboardingScreen(isTutorial: true),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.school,
                  size: 20,
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Tutorial',
                      style: AppTheme.title(size: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Learn how to use all of Forager\'s features',
                      style: AppTheme.caption(size: 11, color: AppTheme.textMedium),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textMedium,
                size: 20,
              ),
            ],
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
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          initiallyExpanded: false,
          leading: Container(
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
          title: Text(
            'Open to Foraging Together',
            style: AppTheme.title(size: 14),
          ),
          subtitle: Text(
            userData.openToForage
                ? 'Tap to edit preferences'
                : 'Toggle to show others you\'re available',
            style: AppTheme.caption(size: 11),
          ),
          trailing: Switch(
            value: userData.openToForage,
            activeTrackColor: AppTheme.success.withValues(alpha: 0.5),
            activeThumbColor: AppTheme.success,
            onChanged: (value) => _toggleOpenToForage(value),
          ),
          children: [
            if (userData.openToForage) ...[
              _buildForagePreferencesSelector(userData),
              const SizedBox(height: 12),
              // Primary forage location
              _buildPrimaryLocationRow(userData),
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
            ] else ...[
              // Show hint when collapsed and disabled
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.textMedium),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enable the toggle to set your foraging preferences and appear in Discover.',
                        style: AppTheme.caption(size: 12, color: AppTheme.textMedium),
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

  Widget _buildLeaderboardVisibilityCard(UserModel userData) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: userData.showOnLeaderboard
                ? AppTheme.xp.withValues(alpha: 0.15)
                : AppTheme.textMedium.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.leaderboard,
            size: 20,
            color: userData.showOnLeaderboard
                ? AppTheme.xp
                : AppTheme.textMedium,
          ),
        ),
        title: Text(
          'Show on Leaderboard',
          style: AppTheme.title(size: 14),
        ),
        subtitle: Text(
          userData.showOnLeaderboard
              ? 'Your rank is visible to everyone'
              : 'You are hidden from leaderboards',
          style: AppTheme.caption(size: 11),
        ),
        trailing: Switch(
          value: userData.showOnLeaderboard,
          activeTrackColor: AppTheme.xp.withValues(alpha: 0.5),
          activeThumbColor: AppTheme.xp,
          onChanged: (value) => _toggleLeaderboardVisibility(value),
        ),
      ),
    );
  }

  Future<void> _toggleLeaderboardVisibility(bool value) async {
    try {
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.update(currentUser.email!, {
        'showOnLeaderboard': value,
      });
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

  Widget _buildForagePreferencesSelector(UserModel userData) {
    // Parse current preferences into a set of selected items
    final currentPrefs = userData.foragePreferences ?? '';
    final selectedTypes = currentPrefs
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet();

    // Get standard forage types
    final standardTypes = ForageTypeUtils.allTypes;

    // Common availability/skill tags
    final availabilityTags = [
      'weekends',
      'weekdays',
      'mornings',
      'evenings',
    ];

    final skillTags = [
      'beginner-friendly',
      'experienced',
      'willing to teach',
      'looking to learn',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: What do you forage?
        Text(
          'What do you forage?',
          style: AppTheme.caption(size: 12, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: standardTypes.map((type) {
            final isSelected = selectedTypes.contains(type.toLowerCase());
            final color = ForageTypeUtils.getTypeColor(type);
            return _buildSelectableChip(
              label: _capitalizeFirst(type),
              isSelected: isSelected,
              color: color,
              onTap: () => _toggleForagePreference(type, selectedTypes, userData),
            );
          }).toList(),
        ),

        // Custom marker types section
        FutureBuilder<List<dynamic>>(
          future: ref.read(customMarkerTypeRepositoryProvider).getByUserId(currentUser.email!),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final customTypes = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Your custom types',
                  style: AppTheme.caption(size: 12, weight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: customTypes.map((customType) {
                    final typeName = customType.name as String;
                    final emoji = customType.emoji as String;
                    final isSelected = selectedTypes.contains(typeName.toLowerCase());
                    return _buildSelectableChip(
                      label: '$emoji $typeName',
                      isSelected: isSelected,
                      color: AppTheme.primary,
                      onTap: () => _toggleForagePreference(typeName, selectedTypes, userData),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        // Section: When are you available?
        Text(
          'When are you available?',
          style: AppTheme.caption(size: 12, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: availabilityTags.map((tag) {
            final isSelected = selectedTypes.contains(tag.toLowerCase());
            return _buildSelectableChip(
              label: _capitalizeFirst(tag),
              isSelected: isSelected,
              color: AppTheme.info,
              onTap: () => _toggleForagePreference(tag, selectedTypes, userData),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Section: Experience level
        Text(
          'Experience level',
          style: AppTheme.caption(size: 12, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skillTags.map((tag) {
            final isSelected = selectedTypes.contains(tag.toLowerCase());
            return _buildSelectableChip(
              label: _capitalizeFirst(tag),
              isSelected: isSelected,
              color: AppTheme.xp,
              onTap: () => _toggleForagePreference(tag, selectedTypes, userData),
            );
          }).toList(),
        ),

        // Show selected summary
        if (selectedTypes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: AppTheme.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${selectedTypes.length} preferences selected',
                    style: AppTheme.caption(size: 11, color: AppTheme.success),
                  ),
                ),
                GestureDetector(
                  onTap: () => _clearAllForagePreferences(),
                  child: Text(
                    'Clear all',
                    style: AppTheme.caption(
                      size: 11,
                      color: AppTheme.textMedium,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.caption(
            size: 11,
            color: isSelected ? Colors.white : color,
            weight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _toggleForagePreference(
    String preference,
    Set<String> currentSelections,
    UserModel userData,
  ) {
    final newSelections = Set<String>.from(currentSelections);
    final lowerPref = preference.toLowerCase();

    if (newSelections.contains(lowerPref)) {
      newSelections.remove(lowerPref);
    } else {
      newSelections.add(lowerPref);
    }

    // Convert back to comma-separated string
    final newPrefsString = newSelections.join(', ');
    _saveForagePreferences(newPrefsString);
  }

  Future<void> _clearAllForagePreferences() async {
    await _saveForagePreferences('');
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    // Handle hyphenated words like "beginner-friendly"
    return text.split('-').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join('-');
  }

  Widget _buildPrimaryLocationRow(UserModel userData) {
    final hasLocation = userData.hasPrimaryForageLocation;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 18,
            color: hasLocation ? AppTheme.primary : AppTheme.textMedium,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Primary Forage Location',
                  style: AppTheme.caption(size: 11, color: AppTheme.textMedium),
                ),
                const SizedBox(height: 2),
                Text(
                  hasLocation
                      ? userData.primaryForageLocation!
                      : 'Not set - will use your marker locations',
                  style: AppTheme.body(
                    size: 13,
                    color: hasLocation ? AppTheme.textDark : AppTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showEditLocationDialog(userData),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              hasLocation ? 'Edit' : 'Set',
              style: AppTheme.caption(
                size: 12,
                color: AppTheme.primary,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditLocationDialog(UserModel userData) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => _LocationPickerDialog(
        currentLocation: userData.primaryForageLocation,
        onSave: _savePrimaryLocation,
        onClear: _clearPrimaryLocation,
        onPickFromMarkers: _showMarkerLocationPicker,
      ),
    );
  }

  Future<void> _showMarkerLocationPicker() async {
    final markerRepo = ref.read(markerRepositoryProvider);
    final markers = await markerRepo.getByUserId(currentUser.email!);

    if (markers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No markers found. Add some forage locations first!'),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Sort by most recent
    markers.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (!mounted) return;

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMedium.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Pick from your markers',
                style: AppTheme.title(size: 16),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: markers.length,
                itemBuilder: (context, index) {
                  final marker = markers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                      child: Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                    ),
                    title: Text(marker.name, style: AppTheme.body(size: 14)),
                    subtitle: Text(
                      marker.type,
                      style: AppTheme.caption(size: 12, color: AppTheme.textMedium),
                    ),
                    onTap: () => Navigator.pop(context, {
                      'lat': marker.latitude,
                      'lng': marker.longitude,
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      // Use geocoding to get a readable address
      final address = await GeocodingCache.getAddress(
        selected['lat'] as double,
        selected['lng'] as double,
      );

      await _savePrimaryLocation(
        address,
        latitude: selected['lat'] as double,
        longitude: selected['lng'] as double,
      );
    }
  }

  Future<void> _savePrimaryLocation(
    String location, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      double lat = latitude ?? 0.0;
      double lng = longitude ?? 0.0;

      // If no coordinates provided, try to geocode the location text
      if (latitude == null || longitude == null) {
        try {
          final locations = await locationFromAddress(location);
          if (locations.isNotEmpty) {
            lat = locations.first.latitude;
            lng = locations.first.longitude;
          }
        } catch (e) {
          // Geocoding failed - warn user but still save the text
          debugPrint('Geocoding failed for "$location": $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not verify "$location". Distance calculations may not work.'),
                backgroundColor: AppTheme.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }

      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.setPrimaryForageLocation(
        userId: currentUser.email!,
        location: location,
        latitude: lat,
        longitude: lng,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Primary location updated'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving location: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _clearPrimaryLocation() async {
    try {
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.clearPrimaryForageLocation(currentUser.email!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location will be detected from your markers'),
            backgroundColor: AppTheme.info,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing location: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
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

/// Dialog for editing the primary forage location
class _LocationPickerDialog extends StatefulWidget {
  final String? currentLocation;
  final Future<void> Function(String, {double? latitude, double? longitude}) onSave;
  final Future<void> Function() onClear;
  final Future<void> Function() onPickFromMarkers;

  const _LocationPickerDialog({
    this.currentLocation,
    required this.onSave,
    required this.onClear,
    required this.onPickFromMarkers,
  });

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentLocation ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      title: Row(
        children: [
          Icon(Icons.location_on, color: AppTheme.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Forage Location', style: AppTheme.title(size: 16)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This helps other foragers find people nearby.',
              style: AppTheme.caption(size: 12, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 16),

            // Pick from markers button (recommended)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onPickFromMarkers();
              },
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Use My Marker Location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 44),
                side: BorderSide(color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '(Recommended - accurate distance)',
                style: AppTheme.caption(size: 10, color: AppTheme.textMedium),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: AppTheme.textMedium.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: AppTheme.caption(color: AppTheme.textMedium)),
                ),
                Expanded(child: Divider(color: AppTheme.textMedium.withValues(alpha: 0.3))),
              ],
            ),
            const SizedBox(height: 16),

            // Manual entry
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'e.g., Portland, Oregon',
                hintStyle: AppTheme.caption(color: AppTheme.textLight),
                labelText: 'Enter city/region',
                labelStyle: AppTheme.caption(size: 12),
                filled: true,
                fillColor: AppTheme.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: AppTheme.body(size: 14),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.currentLocation != null)
          TextButton(
            onPressed: () async {
              await widget.onClear();
              if (context.mounted) Navigator.pop(context, true);
            },
            child: Text(
              'Clear',
              style: AppTheme.button(color: AppTheme.textMedium),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: AppTheme.button(color: AppTheme.textMedium),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  final location = _controller.text.trim();
                  if (location.isEmpty) {
                    Navigator.pop(context, false);
                    return;
                  }

                  setState(() => _isLoading = true);
                  await widget.onSave(location);
                  if (context.mounted) Navigator.pop(context, true);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
