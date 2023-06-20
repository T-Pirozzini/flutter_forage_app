import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import 'package:flutter_forager_app/components/speed_dial.dart';
import 'package:flutter_forager_app/pages/forage_locations_page.dart';
import 'package:flutter_forager_app/pages/friends_page.dart';
import 'package:flutter_forager_app/pages/profile_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/drawer.dart';
import 'chat_page.dart';
import 'explore_page.dart';
import 'map_page.dart';

class HomePage extends StatefulWidget {
  final double lat;
  final double lng;
  final int currentIndex;

  const HomePage(
      {super.key,
      required this.lat,
      required this.lng,
      required this.currentIndex});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // get current user id
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  // bottom navigation bar
  int currentIndex = 0;

  @override
  void initState() {
    currentIndex = widget.currentIndex;
    super.initState();
  }

  final pages = [
    const MapPage(),
    const ExplorePage(lat: 37.42, lng: -122.08),
    const FriendsPage(),
    const ChatPage(),
  ];

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

  // navigate to forage locations page
  void goToForageLocationsPage() {
    // pop menu drawer
    Navigator.pop(context);
    // go to new page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForageLocations(userId: currentUserId),
      ),
    );
  }

  // sign user out
  void signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FORAGER'),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 34, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade300,
      ),
      drawer: CustomDrawer(
        onProfileTap: goToProfilePage,
        onSignOutTap: signOut,
        onForageLocationsTap: goToForageLocationsPage,
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
          FloatingNavbarItem(icon: Icons.explore, title: 'Explore'),
          FloatingNavbarItem(icon: Icons.group, title: 'Friends'),
          FloatingNavbarItem(icon: Icons.forum, title: 'Community'),
        ],
      ),
    );
  }
}
