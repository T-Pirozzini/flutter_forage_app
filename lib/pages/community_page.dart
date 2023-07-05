import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunityPage extends StatefulWidget {
  

  const CommunityPage({super.key, });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COMMUNITY'),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade400,
      ),
      body: const Center(
        child: Text('Community Page'),
      ),
    );
  }
}
