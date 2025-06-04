import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/components/ad_mob_service.dart';
import 'package:flutter_forager_app/components/screen_heading.dart';
import 'package:flutter_forager_app/models/user.dart';
import 'package:flutter_forager_app/providers/marker_count_provider.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_locations_page.dart';
import 'package:flutter_forager_app/screens/friends/friends_controller.dart';
import 'package:flutter_forager_app/screens/profile/info_card.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    String newUsername = username;
    String newBio = bio;
    String newProfileImage = selectedProfileOption;
    String newBackgroundImage = selectedBackgroundOption;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.grey[900],
            insetPadding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Edit Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Username field
                    TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Username",
                        labelStyle: const TextStyle(color: Colors.white),
                        hintText: "Enter new username",
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) => newUsername = value,
                      controller: TextEditingController(text: username),
                    ),
                    const SizedBox(height: 16),

                    // Bio field
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Bio",
                        labelStyle: const TextStyle(color: Colors.white),
                        hintText: "Tell us about yourself",
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) => newBio = value,
                      controller: TextEditingController(text: bio),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // Profile Image Selection
                    const Text(
                      "Select Profile Image",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 180, // Smaller fixed height
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Scrollbar(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: imageProfileOptions.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                            final option = imageProfileOptions[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  newProfileImage = option;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image:
                                        AssetImage('lib/assets/images/$option'),
                                    fit: BoxFit.cover,
                                  ),
                                  border: newProfileImage == option
                                      ? Border.all(
                                          color: Colors.deepOrange, width: 3)
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Background Image Selection
                    const Text(
                      "Select Background Image",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 180, // Smaller fixed height
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Scrollbar(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: imageBackgroundOptions.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                            final option = imageBackgroundOptions[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  newBackgroundImage = option;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image:
                                        AssetImage('lib/assets/images/$option'),
                                    fit: BoxFit.cover,
                                  ),
                                  border: newBackgroundImage == option
                                      ? Border.all(
                                          color: Colors.deepOrange, width: 3)
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryColor,
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () async {
                            // Update local state
                            setState(() {
                              username = newUsername.trim().isNotEmpty
                                  ? newUsername
                                  : username;
                              bio = newBio.trim().isNotEmpty ? newBio : bio;
                              selectedProfileOption = newProfileImage;
                              selectedBackgroundOption = newBackgroundImage;
                            });

                            // Update in Firestore
                            await usersCollection
                                .doc(currentUser.email)
                                .update({
                              'username': username,
                              'bio': bio,
                              'profilePic': selectedProfileOption,
                              'profileBackground': selectedBackgroundOption,
                            });

                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
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
          buildTop(),
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
                        Container(
                          height: 100,
                          margin: const EdgeInsets.all(8.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Text(
                            bio,
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InfoCard(
                              icon: Icons.location_on,
                              text: 'Your Forage Locations',
                              countText: '$markerCount saved location(s).',
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
                              countText:
                                  '$nonOwnerMarkerCount bookmarked location(s).',
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
                            InfoCard(
                              icon: Icons.group,
                              text: 'Friends Locations',
                              countText:
                                  '${userData['friends'].length} friend(s).',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const FriendsController(currentTab: 0),
                                  ),
                                );
                              },
                            ),
                            InfoCard(
                              icon: Icons.person_add,
                              text: 'Friend requests',
                              countText:
                                  'Incoming: ${userData['friendRequests'].length} '
                                  'Outgoing: ${userData['sentFriendRequests'].length}',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const FriendsController(currentTab: 1),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTop() {
    final top = coverHeight - profileHeight / 2 - 25;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          child: buildCoverImage(),
        ),
        Positioned(
          top: top - 80,
          child: buildProfileImage(),
        ),
        Positioned(
          top: top + 20,
          child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: StyledTitle(username.isNotEmpty ? username : 'Username')),
        )
      ],
    );
  }

  Widget buildCoverImage() => ClipPath(
        clipper: _BottomCurveClipper(),
        child: Container(
          color: Colors.white,
          child: Image.asset(
            'lib/assets/images/$selectedBackgroundOption',
            width: double.infinity,
            height: coverHeight - 60,
            fit: BoxFit.cover,
          ),
        ),
      );

  Widget buildProfileImage() => Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4.0,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            'lib/assets/images/$selectedProfileOption',
            width: profileHeight,
            height: profileHeight,
            fit: BoxFit.cover,
          ),
        ),
      );
}

// curve for the background image
class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
        size.width / 2, size.height * 1.3, size.width, size.height - 80);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
