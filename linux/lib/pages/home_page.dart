import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import 'package:flutter_forager_app/screens/forage/speed_dial.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_locations_page.dart';
import 'package:flutter_forager_app/screens/friends/friends_page.dart';
import 'package:flutter_forager_app/screens/profile/profile_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/drawer.dart';
import 'about_page.dart';
import 'about_us_page.dart';
import 'community_page.dart';
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

  @override
  void initState() {
    super.initState();
    followUser = widget.followUser;
    lat = widget.lat;
    lng = widget.lng;
  }

  // navigate to profile page
  void goToProfilePage() {
    // pop menu drawer
    Navigator.pop(context);
    // go to new page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    );
  }

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
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      MapPage(lat: lat, lng: lng, followUser: followUser),
      ForageLocations(
          userId: currentUser.email!,
          userName: currentUser.email!.split("@")[0]),
      const FriendsPage(),
      const CommunityPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FORAGER'),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 34, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade300,
        elevation: 2,
      ),
      drawer: CustomDrawer(
        onProfileTap: goToProfilePage,
        onSignOutTap: signOut,
        onForageLocationsTap: goToForageLocationsPage,
        onAboutTap: goToAboutPage,
        onAboutUsTap: goAboutUsPage,
      ),
      body: pages[currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      floatingActionButton:
          pages[currentIndex] is MapPage ? const MarkerButtons() : null,
      extendBody: true,
      bottomNavigationBar: FloatingNavbar(
        onTap: (index) => setState(() => currentIndex = index),
        currentIndex: currentIndex,
        backgroundColor: Colors.grey.shade800,
        selectedItemColor: Colors.black,
        selectedBackgroundColor: Colors.deepOrange.shade300,
        unselectedItemColor: Colors.white,
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
