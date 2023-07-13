import 'package:flutter/material.dart';
import 'package:flutter_forager_app/pages/home_page.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ABOUT FORAGER'),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade400,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(
                  lat: 0,
                  lng: 0,
                  followUser: true,
                  currentIndex: 0,
                ),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Stack(
            children: [
              Image.asset('lib/assets/images/autumn_background.jpg'),
              Container(
                color: Colors.blue.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Center(
                  child: Text(
                    'This mobile app allows you to mark locations of fish, trees, berries, ferns, and mushrooms on to your map. You\'re allowed allowed to save up to 10 locations per account with the custom markers inside the speed dial switch on the map page. Once you are friends with someone, you can view each other\'s saved locations.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
