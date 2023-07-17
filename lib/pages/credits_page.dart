import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_page.dart';

class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
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
      body: const Column(
        children: [
          Text('Smashing Stocks'),
          Text("'https://www.flaticon.com/authors/smashicons'"),
        ],
      ),
    );
  }
}
