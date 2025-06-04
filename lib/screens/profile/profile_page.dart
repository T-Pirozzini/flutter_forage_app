import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/components/ad_mob_service.dart';
import 'package:flutter_forager_app/components/screen_heading.dart';
import 'package:flutter_forager_app/models/user.dart';
import 'package:flutter_forager_app/providers/marker_count_provider.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_locations_page.dart';
import 'package:flutter_forager_app/screens/friends/friends_controller.dart';
import 'package:flutter_forager_app/screens/profile/components/about_me.dart';
import 'package:flutter_forager_app/screens/profile/components/edit_profile_dialog.dart';
import 'package:flutter_forager_app/screens/profile/components/info_card.dart';
import 'package:flutter_forager_app/screens/profile/components/user_heading.dart';
import 'package:flutter_forager_app/screens/recipes/recipes_page.dart';

import 'package:flutter_forager_app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final UserModel user;

  const ProfilePage({required this.user, Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  // all users
  final usersCollection = FirebaseFirestore.instance.collection('Users');

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
  bool get _isCurrentUser => widget.user.uid == currentUser.uid;
  bool get _isFriend => widget.user.friends.contains(currentUser.uid);

  @override
  void initState() {
    super.initState();
    final markerCountNotifier = ref.read(markerCountProvider.notifier);
    final nonOwnerMarkerCountNotifier =
        ref.read(nonOwnerMarkerCountProvider.notifier);

    markerCountNotifier.updateMarkerCount(currentUser.email!, true);
    nonOwnerMarkerCountNotifier.updateNonOwnerMarkerCount(currentUser.email!);
    loadUserProfileImages();
  }

  void loadUserProfileImages() async {
    final docSnapshot = await usersCollection.doc(currentUser.email).get();
    if (docSnapshot.exists) {
      final userData = docSnapshot.data() as Map<String, dynamic>;
      setState(() {
        selectedBackgroundOption =
            userData['profileBackground'] ?? selectedBackgroundOption;
        selectedProfileOption = userData['profilePic'] ?? selectedProfileOption;
        username = userData['username'] ?? '';
        bio = userData['bio'] ?? '';
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

          await usersCollection.doc(currentUser.email).update({
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
    final markerCount = ref.watch(markerCountProvider);
    final nonOwnerMarkerCount = ref.watch(nonOwnerMarkerCountProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondaryColor,
        onPressed: showProfileEditDialog,
        child: Icon(Icons.edit, color: AppColors.textColor),
        mini: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
      body: Column(
        children: [
          ScreenHeading(title: 'Profile'),
          UserHeading(
            selectedBackgroundOption: selectedBackgroundOption,
            selectedProfileOption: selectedProfileOption,
            username: username,
          ),
          // buildTop(),
          const SizedBox(height: 50),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(currentUser.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  selectedBackgroundOption =
                      userData['profileBackground'] ?? selectedBackgroundOption;
                  selectedProfileOption =
                      userData['profilePic'] ?? selectedProfileOption;
                  username = userData['username'] ?? '';
                  bio = userData['bio'] ?? '';

                  return Center(
                    child: ListView(
                      children: [
                        AboutMe(bio: bio),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Text(
                                'ACTIVITY STATS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            // Stats Grid
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              childAspectRatio: 1.5,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              children: [
                                _buildStatCard(
                                  context,
                                  icon: Icons.location_on,
                                  title: 'Locations',
                                  value: widget.user.forageStats['locations']
                                          ?.toString() ??
                                      '0',
                                  onTap: () {
                                    if (_isCurrentUser || _isFriend) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ForageLocations(
                                            userId: widget.user.uid,
                                            userName: widget.user.username,
                                            userLocations: true,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  enabled: _isCurrentUser || _isFriend,
                                ),
                                _buildStatCard(
                                  context,
                                  icon: Icons.menu_book,
                                  title: 'Recipes',
                                  value: widget.user.savedRecipes.length
                                      .toString(),
                                  onTap: () {
                                    if (_isCurrentUser || _isFriend) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const RecipesPage()),
                                      );
                                    }
                                  },
                                  enabled: _isCurrentUser || _isFriend,
                                ),
                                _buildStatCard(
                                  context,
                                  icon: Icons.people,
                                  title: 'Friends',
                                  value: widget.user.friends.length.toString(),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const FriendsController(
                                                currentTab: 0),
                                      ),
                                    );
                                  },
                                  enabled: true,
                                ),
                                _buildStatCard(
                                  context,
                                  icon: Icons.calendar_today,
                                  title: 'Member Since',
                                  value: DateFormat('MMM yyyy')
                                      .format(widget.user.createdAt.toDate()),
                                  onTap: null,
                                  enabled: false,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Friend Action Button
                            if (!_isCurrentUser)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildFriendActionButton(context),
                              ),

                            // Friend Requests Button (for current user)
                            if (_isCurrentUser &&
                                widget.user.friendRequests.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.person_add, size: 20),
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

                            // Section Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'ACTIONS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),

                            // Action Cards
                            Column(
                              children: [
                                InfoCard(
                                  icon: Icons.location_on,
                                  text: 'Your Forage Locations',
                                  countText: '$markerCount saved',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ForageLocations(
                                          userId: currentUser.email!,
                                          userName:
                                              currentUser.email!.split("@")[0],
                                          userLocations: true,
                                        ),
                                      ),
                                    );
                                    AdMobService.showInterstitialAd();
                                  },
                                ),
                                InfoCard(
                                  icon: Icons.bookmark,
                                  text: 'Community Locations',
                                  countText: '$nonOwnerMarkerCount bookmarked',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ForageLocations(
                                          userId: currentUser.email!,
                                          userName: "Bookmarked Locations",
                                          userLocations: false,
                                        ),
                                      ),
                                    );
                                    AdMobService.showInterstitialAd();
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 100),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 24, color: enabled ? Colors.deepOrange : Colors.grey),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.black : Colors.grey)),
              const SizedBox(height: 4),
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      color: enabled ? Colors.grey[600] : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendActionButton(BuildContext context) {
    // final isFriend = widget.user.friends.contains(currentUser.uid);
    // final hasSentRequest =
    //     widget.user.friendRequests.containsKey(currentUser.uid);
    // final hasReceivedRequest =
    //     widget.user.friendRequests.containsValue(currentUser.uid);

    final isFriend = true;
    final hasSentRequest = false;
    final hasReceivedRequest = false;

    if (isFriend) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.check, size: 20),
        label: const Text('Friends'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[50],
          foregroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: null,
      );
    } else if (hasSentRequest) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.person_add_disabled, size: 20),
        label: const Text('Request Sent'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          // Cancel friend request logic
        },
      );
    } else if (hasReceivedRequest) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[50],
                foregroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
              ),
              onPressed: () {
                // Accept friend request logic
              },
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.close, size: 20),
              label: const Text('Decline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(12),
                  ),
                ),
              ),
              onPressed: () {
                // Decline friend request logic
              },
            ),
          ),
        ],
      );
    } else {
      return ElevatedButton.icon(
        icon: const Icon(Icons.person_add, size: 20),
        label: const Text('Add Friend'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange[50],
          foregroundColor: Colors.deepOrange,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          // Send friend request logic
        },
      );
    }
  }
}
