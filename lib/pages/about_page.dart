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
      backgroundColor: Colors.grey.shade800,
      appBar: AppBar(
        title: const Text('APP INFO'),
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
      body: const Padding(
        padding: EdgeInsets.all(10.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Welcome to Forager!",
                  style: TextStyle(fontSize: 24, color: Colors.white)),
              SizedBox(height: 20),
              Text(
                'We created this app to help foster a deeper connection with nature by encouraging users to explore the wilderness around them. Our app is designed to help people discover and exchange information about forageable items in the wild, inspiring a sense of adventure and appreciation for the natural world. By providing a platform for users to share their findings with friends and the wider community, we aim to build a vibrant network of nature enthusiasts who can collaboratively explore, learn, and celebrate the wonders of the great outdoors. Together, we aspire to nurture a community that values sustainability, conservation, and the joy of discovering hidden treasures amidst the beauty of our natural landscapes.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Embark on a captivating adventure with our interactive map feature. The marker faithfully traces your path, unveiling the thrill of unique discoveries. Create personalized markers, capture moments with photos, and save them as exclusive, cherished reminders.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Connect with friends and fellow explorers, exchanging locations to inspire exciting journeys. Discover hidden gems on the map, fostering camaraderie and discovery.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Safeguard your treasures while contributing to the adventure. Keep special spots exclusive to your exploration, or share them on the community board to spark enthusiasm among nature enthusiasts.',
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
      ),
    );
  }
}
