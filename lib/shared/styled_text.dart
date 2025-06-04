import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class StyledText extends StatelessWidget {
  const StyledText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.kanit(
        textStyle: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class StyledHeading extends StatelessWidget {
  const StyledHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.eduNswActFoundation(
          fontSize: 24,
          color: AppColors.titleColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 3.5),
    );
  }
}

class StyledTitle extends StatelessWidget {
  const StyledTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.eduNswActFoundation(
        textStyle: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class StyledActionText extends StatelessWidget {
  const StyledActionText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.eduNswActFoundation(
        textStyle: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
