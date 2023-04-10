import 'package:flutter/material.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import 'package:flutter_forager_app/components/speed_dial.dart';
import 'package:google_fonts/google_fonts.dart';
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
    const MapPage(),
  ];

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
          FloatingNavbarItem(icon: Icons.chat_bubble_outline, title: 'Chats'),
          FloatingNavbarItem(icon: Icons.settings, title: 'Settings'),
        ],
      ),
    );
  }
}
