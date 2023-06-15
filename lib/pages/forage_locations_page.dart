import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForageLocations extends StatefulWidget {
  const ForageLocations({super.key});

  @override
  State<ForageLocations> createState() => _ForageLocationsState();
}

class _ForageLocationsState extends State<ForageLocations> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY FORAGE LOCATIONS'),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade300,
      ),
      body: const Center(
        child: Text('Forage Locations'),
      ),
    );
  }
}
