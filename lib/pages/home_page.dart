import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import 'package:flutter_forager_app/components/ad_mob_service.dart';
import 'package:flutter_forager_app/components/speed_dial.dart';
import 'package:flutter_forager_app/pages/forage_locations_page.dart';
import 'package:flutter_forager_app/pages/friends_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../auth/auth_page.dart';
import '../components/drawer.dart';
import 'about_page.dart';
import 'about_us_page.dart';
import 'community_page.dart';
import 'credits_page.dart';
import 'map_page.dart';

class HomePage extends StatefulWidget {
  final double lat;
  final double lng;
  final int currentIndex;
  final bool followUser;

  const HomePage(
      {super.key,
      required this.lat,
      required this.lng,
      required this.followUser,
      required this.currentIndex});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // get current user id
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  // get current user
  final currentUser = FirebaseAuth.instance.currentUser!;
  // bottom navigation bar
  late bool followUser;
  int currentIndex = 0;
  double lat = 0;
  double lng = 0;

  BannerAd? _banner;

  @override
  void initState() {
    super.initState();
    followUser = widget.followUser;
    lat = widget.lat;
    lng = widget.lng;
    currentIndex = widget.currentIndex;

    _createBannerAd();
  }

  void _createBannerAd() {
    _banner = BannerAd(
      adUnitId: AdMobService.bannerAdUnitId!,
      size: AdSize.fullBanner,
      listener: AdMobService.bannerListener,
      request: const AdRequest(),
    )..load();
  }

  // // navigate to profile page
  // void goToProfilePage() {
  //   // pop menu drawer
  //   Navigator.pop(context);
  //   // go to new page
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const ProfilePage(),
  //     ),
  //   );
  // }

  // navigate to profile page
  void goToAboutPage() {
    // pop menu drawer
    Navigator.pop(context);
    // go to new page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutPage(),
      ),
    );
  }

  // navigate to profile page
  void goAboutUsPage() {
    // pop menu drawer
    Navigator.pop(context);
    // go to new page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutUsPage(),
      ),
    );
  }

  // navigate to credits page
  void goCreditsPage() {
    // pop menu drawer
    Navigator.pop(context);
    // go to new page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreditsPage(),
      ),
    );
  }

  // navigate to forage locations page
  void goToForageLocationsPage() {
    // pop menu drawer
    Navigator.pop(context);
    // go to new page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForageLocations(
          userId: currentUser.email!,
          userName: currentUser.email!.split("@")[0],
        ),
      ),
    );
  }

  // sign user out
  void signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthPage()),
    );
  }

  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Account Deletion'),
          content: Text(
            'We are sad to see you go. Are you sure you would like to delete your account? This action will be permanent.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                deleteAccount();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void deleteAccount() async {
    try {
      // Delete the user's account
      await FirebaseAuth.instance.currentUser?.delete();

      // Navigate to AuthPage after successful deletion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()),
      );
    } catch (e) {
      print('Error deleting account: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      MapPage(lat: lat, lng: lng, followUser: followUser),
      ForageLocations(
          userId: currentUser.email!,
          userName: currentUser.email!.split("@")[0]),
      const FriendsController(),
      const CommunityPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FORAGER',
          style: TextStyle(letterSpacing: 2.5),
        ),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 34, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade300,
        elevation: 2,
      ),
      drawer: CustomDrawer(
        // onProfileTap: goToProfilePage,
        onSignOutTap: signOut,
        onForageLocationsTap: goToForageLocationsPage,
        onAboutTap: goToAboutPage,
        onAboutUsTap: goAboutUsPage,
        onCreditsTap: goCreditsPage,
        showDeleteConfirmationDialog: showDeleteConfirmationDialog,
      ),
      body: Column(
        children: [
          Expanded(
            child: pages[currentIndex], // Main content of the page
          ),
          _banner != null
              ? Container(
                  height: 50,
                  child: AdWidget(ad: _banner!),
                )
              : SizedBox.shrink(), // Banner ad or empty container
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: pages[currentIndex] is MapPage
          ? Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: const MarkerButtons(),
            )
          : null,
      extendBody: true,
      bottomNavigationBar: FloatingNavbar(
        onTap: (index) => setState(() => currentIndex = index),
        currentIndex: currentIndex,
        backgroundColor: Colors.grey.shade800,
        selectedItemColor: Colors.black,
        selectedBackgroundColor: Colors.deepOrange.shade300,
        unselectedItemColor: Colors.white,
        margin: EdgeInsets.fromLTRB(0, 0, 0, 50),
        items: [
          FloatingNavbarItem(icon: Icons.map, title: 'Forage'),
          FloatingNavbarItem(icon: Icons.hotel_class_sharp, title: 'Locations'),
          FloatingNavbarItem(icon: Icons.group, title: 'Friends'),
          FloatingNavbarItem(icon: Icons.forum, title: 'Community'),
        ],
      ),
    );
  }
}
