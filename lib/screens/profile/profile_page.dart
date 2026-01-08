import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/shared/screen_heading.dart';
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
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
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
        selectedProfileOption = user.profilePic.isNotEmpty
            ? user.profilePic
            : 'profileImage1.jpg';
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
        gradient: AppColors.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: widget.showBackButton
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.textColor),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  _isCurrentUser
                      ? 'My Profile'
                      : '${widget.user.username}\'s Profile',
                  style: TextStyle(color: AppColors.textColor),
                ),
                centerTitle: true,
                // Only show edit button for current user
                actions: _isCurrentUser
                    ? [
                        IconButton(
                          icon: Icon(Icons.edit, color: AppColors.textColor),
                          onPressed: showProfileEditDialog,
                        ),
                      ]
                    : null,
              )
            : null,
        // Show floating action button only when there's no AppBar
        floatingActionButton: !widget.showBackButton && _isCurrentUser
            ? FloatingActionButton(
                backgroundColor: AppColors.secondaryColor,
                onPressed: showProfileEditDialog,
                child: Icon(Icons.edit, color: AppColors.textColor),
                mini: true,
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
        body: Column(
          children: [
            ScreenHeading(
                title: _isCurrentUser
                    ? 'Profile'
                    : '${widget.user.username}\'s Profile'),
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
                stream: ref.read(userRepositoryProvider).streamById(_profileUserId),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final userData = snapshot.data!;
                    selectedBackgroundOption = userData.profileBackground.isNotEmpty
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
                                      recipeCount = recipeSnapshot.data.toString();
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
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  child: OutlinedButton.icon(
                                    icon:
                                        const Icon(Icons.person_add, size: 20),
                                    label: Text(
                                      'Friend Requests (${widget.user.friendRequests.length})',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.deepOrange,
                                      side: const BorderSide(
                                          color: Colors.deepOrange),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const FriendsController(
                                                  currentTab: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              // Tutorial/Help Button (only for current user)
                              if (_isCurrentUser)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.help_outline, size: 20),
                                    label: const Text(
                                      'App Tutorial',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.secondaryColor,
                                      side: BorderSide(
                                          color: AppColors.secondaryColor),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: enabled ? Colors.white : Colors.grey[100],
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: enabled ? Colors.deepOrange : Colors.grey,
                ),
                const SizedBox(height: 8),
                AutoSizeText(
                  value,
                  minFontSize: 6,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: enabled ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                AutoSizeText(
                  title,
                  minFontSize: 6,
                  maxLines: 1,
                  style: TextStyle(
                    color: enabled ? Colors.grey[600] : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
