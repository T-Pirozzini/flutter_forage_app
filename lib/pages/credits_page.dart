import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_page.dart';

class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade800,
      appBar: AppBar(
        title: const Text('CREDITS', style: TextStyle(letterSpacing: 2.5)),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Icons: Flaticon',
                style: TextStyle(fontSize: 24, color: Colors.white)),
            Text("'Smashing Stocks' from www.flaticon.com",
                style: TextStyle(fontSize: 16, color: Colors.white)),
            Text("'ultimatearm' from www.flaticon.com",
                style: TextStyle(fontSize: 16, color: Colors.white)),
            Text("'Adib Sulthon' from www.flaticon.com",
                style: TextStyle(fontSize: 16, color: Colors.white)),
            Text("'DinosoftLabs' from www.flaticon.com",
                style: TextStyle(fontSize: 16, color: Colors.white)),
            Text("'Futuer' from www.flaticon.com",
                style: TextStyle(fontSize: 16, color: Colors.white)),
            Text("'popo2021' from www.flaticon.com",
                style: TextStyle(fontSize: 16, color: Colors.white)),
            Text("'amonrat rungreangfangsai' from www.flaticon.com",
                style: TextStyle(fontSize: 16, color: Colors.white)),
            Text("'lapiyee' from www.flaticon.com",
                style: TextStyle(fontSize: 16, color: Colors.white)),
            SizedBox(height: 40),
            Text('Backgrounds: Unsplash',
                style: TextStyle(fontSize: 24, color: Colors.white)),
            Text("'Nature' by 'Luca Bravo' from www.unsplash.com",
                style: TextStyle(fontSize: 16, color: Colors.white)),
            Text("'Woodland' by 'Lukasz Szmigiel' from www.unsplash.com",
                style: TextStyle(fontSize: 16, color: Colors.white)),
            Text("'Fishing' by 'James Wheeler' from www.unsplash.com",
                style: TextStyle(fontSize: 16, color: Colors.white)),
            Text("'Berries' by 'Will' from www.unsplash.com",
                style: TextStyle(fontSize: 16, color: Colors.white)),
            Text("'Mushrooming' by 'Irina Lacob' from www.unsplash.com",
                style: TextStyle(fontSize: 16, color: Colors.white)),
            SizedBox(height: 80),
            Text('Thank you!',
                style: TextStyle(fontSize: 24, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
