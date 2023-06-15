import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import 'package:flutter_forager_app/components/speed_dial.dart';
import 'package:flutter_forager_app/pages/forage_locations_page.dart';
import 'package:flutter_forager_app/pages/profile_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/drawer.dart';
import 'chat_page.dart';
import 'explore_page.dart';
import 'map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // bottom navigation bar
  int currentIndex = 0;
  final pages = [
    const MapPage(),
    const ExplorePage(),
    const ChatPage(),
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
        builder: (context) => const ForageLocations(),
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
          FloatingNavbarItem(icon: Icons.home, title: 'Home'),
          FloatingNavbarItem(icon: Icons.explore, title: 'Explore'),
          FloatingNavbarItem(icon: Icons.chat_bubble_outline, title: 'Chat'),
          FloatingNavbarItem(icon: Icons.settings, title: 'Settings'),
        ],
      ),
    );
  }
}
