import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/auth/auth_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primarySwatch: Colors.deepOrange,
          textTheme: GoogleFonts.alegreyaSansTextTheme()),
      home: const AuthPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
