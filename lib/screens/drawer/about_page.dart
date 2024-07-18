import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/home/home_page.dart';
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
      backgroundColor: Colors.grey.shade800,
      appBar: AppBar(
        title: Text('APP INFO'),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade400,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome to Forager!",
                style: TextStyle(fontSize: 24, color: Colors.white)),
            SizedBox(height: 20),
            Text(
              'Our app fosters a deeper bond with nature, encouraging exploration and discovery of wild forageables. It\'s a platform for sharing findings, igniting adventure, and appreciating nature. Our goal is to create a community of nature enthusiasts who value sustainability, conservation, and the joy of unearthing hidden natural treasures.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Our interactive map offers an exciting journey, tracking your path and revealing unique discoveries. Personalize markers, capture moments with photos, and save these special memories.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Link up with friends and explorers to share locations and uncover hidden gems, enhancing camaraderie and adventure.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Protect your discoveries while adding to the adventure. Choose to keep special spots private or share them with the community to inspire fellow nature lovers.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 50),
            Text(
              'We hope you enjoy your journey with Forager!',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
