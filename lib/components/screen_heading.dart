import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ScreenHeading extends StatelessWidget {
  const ScreenHeading({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: AppColors.titleBarColor,
      alignment: Alignment.center,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.philosopher(
            fontSize: 24,
            color: AppColors.titleColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 3.5),
      ),
    );
  }
}
