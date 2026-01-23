import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/providers/markers/marker_data.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_locations_page.dart';
import 'package:flutter_forager_app/screens/friends/friends_controller.dart';
import 'package:flutter_forager_app/screens/onboarding/onboarding_screen.dart';
import 'package:flutter_forager_app/screens/profile/components/about_me.dart';
import 'package:flutter_forager_app/screens/profile/components/edit_profile_dialog.dart';
import 'package:flutter_forager_app/screens/profile/components/user_heading.dart';
import 'package:flutter_forager_app/screens/recipes/recipes_page.dart';
import 'package:flutter_forager_app/screens/achievements/achievements_page.dart';
import 'package:flutter_forager_app/screens/leaderboard/leaderboard_page.dart';
import 'package:flutter_forager_app/shared/gamification/stats_card.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
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
        body: Column(
          children: [
            // Removed ScreenHeading - user already knows they're on their profile
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final adjustedCoverHeight = screenWidth < 400 ? 150.0 : 200.0;
                final adjustedProfileHeight = screenWidth < 400 ? 80.0 : 100.0;
                return UserHeading(
                  username: username,
                  selectedBackgroundOption: selectedBackgroundOption,
                  selectedProfileOption: selectedProfileOption,
                  createdAt: createdAt,
                  lastActive: lastActive,
                  coverHeight: adjustedCoverHeight,
                  profileHeight: adjustedProfileHeight,
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<UserModel?>(
                stream:
                    ref.read(userRepositoryProvider).streamById(_profileUserId),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final userData = snapshot.data!;
                    selectedBackgroundOption =
                        userData.profileBackground.isNotEmpty
                            ? userData.profileBackground
                            : selectedBackgroundOption;
                    selectedProfileOption = userData.profilePic.isNotEmpty
                        ? userData.profilePic
                        : selectedProfileOption;
                    username = userData.username;
                    bio = userData.bio;

                    return Center(
                      child: ListView(
                        children: [
                          AboutMe(bio: bio, username: username),
                          // Gamification Stats Card
                          if (_isCurrentUser)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: StatsCard(
                                user: userData,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AchievementsPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          // Progress Section - Achievements & Leaderboard
                          if (_isCurrentUser)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildProgressButton(
                                      icon: Icons.workspace_premium,
                                      label: 'Achievements',
                                      color: AppTheme.xp,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AchievementsPage(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildProgressButton(
                                      icon: Icons.leaderboard,
                                      label: 'Leaderboard',
                                      color: AppTheme.secondary,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LeaderboardPage(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: StyledText(
                                      _isCurrentUser
                                          ? 'View saved locations, bookmarks, recipes or friends.'
                                          : 'View ${widget.user.username}\'s locations, recipes and friends.',
                                    ),
                                  ),
                                ),
                              ),
                              // Stats Grid
                              FutureBuilder<int>(
                                future: ref
                                    .read(recipeRepositoryProvider)
                                    .getRecipeCountByUser(_profileUserId),
                                builder: (context, recipeSnapshot) {
                                  String recipeCount = '0';
                                  if (recipeSnapshot.connectionState ==
                                      ConnectionState.done) {
                                    if (recipeSnapshot.hasData) {
                                      recipeCount =
                                          recipeSnapshot.data.toString();
                                    } else if (recipeSnapshot.hasError) {
                                      recipeCount = 'Err';
                                    }
                                  }
                                  return GridView.count(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 4,
                                    childAspectRatio: 1,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    mainAxisSpacing: 4,
                                    crossAxisSpacing: 4,
                                    children: [
                                      _buildStatCard(
                                        context,
                                        icon: Icons.location_on,
                                        title: 'Locations',
                                        value: userMarkers.value?.length
                                                .toString() ??
                                            '0',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ForageLocations(
                                                userId: _profileUserId,
                                                userName: username,
                                                userLocations: true,
                                              ),
                                            ),
                                          );
                                        },
                                        enabled: true,
                                      ),
                                      _buildStatCard(
                                        context,
                                        icon: Icons.bookmark,
                                        title: 'Bookmarked',
                                        value: communityMarkers.value?.length
                                                .toString() ??
                                            '0',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ForageLocations(
                                                userId: _profileUserId,
                                                userName:
                                                    "Bookmarked Locations",
                                                userLocations: false,
                                              ),
                                            ),
                                          );
                                        },
                                        enabled:
                                            _isCurrentUser, // Only allow current user to view bookmarks
                                      ),
                                      _buildStatCard(
                                        context,
                                        icon: Icons.menu_book,
                                        title: 'Recipes',
                                        value: recipeCount,
                                        onTap: () {
                                          // Navigate to recipes page for this user
                                          // You'll need to implement this navigation
                                        },
                                        enabled: _isCurrentUser ||
                                            _isFriend ||
                                            recipeCount != '0',
                                      ),
                                      _buildStatCard(
                                        context,
                                        icon: Icons.people,
                                        title: 'Friends',
                                        value: widget.user.friends.length
                                            .toString(),
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
                                          // For friends, you might want to show a limited friends list
                                        },
                                        enabled:
                                            _isCurrentUser, // Only allow current user to navigate to friends
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 60),

                              // Friend Requests Button (only for current user)
                              if (_isCurrentUser &&
                                  widget.user.friendRequests.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.space16,
                                      vertical: AppTheme.space8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.accentGradient,
                                      borderRadius: AppTheme.borderRadiusMedium,
                                      boxShadow: AppTheme.shadowMedium,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius:
                                            AppTheme.borderRadiusMedium,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const FriendsController(
                                                      currentTab: 1),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: AppTheme.space16),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.person_add,
                                                  size: 20,
                                                  color: AppTheme.textWhite),
                                              const SizedBox(
                                                  width: AppTheme.space8),
                                              Text(
                                                'Friend Requests (${widget.user.friendRequests.length})',
                                                style: AppTheme.title(
                                                  size: 14,
                                                  color: AppTheme.textWhite,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Tutorial/Help Button (only for current user)
                              if (_isCurrentUser)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.space16,
                                      vertical: AppTheme.space8),
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.help_outline,
                                        size: 20),
                                    label: Text(
                                      'App Tutorial',
                                      style: AppTheme.title(
                                          size: 14, color: AppTheme.secondary),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.secondary,
                                      side: BorderSide(
                                          color: AppTheme.secondary, width: 2),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: AppTheme.space16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            AppTheme.borderRadiusMedium,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const OnboardingScreen(
                                                  isTutorial: true),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
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
          ],
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

  Widget _buildProgressButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusMedium,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadiusMedium,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.title(
                  size: 14,
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
}
