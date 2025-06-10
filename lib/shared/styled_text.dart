import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class StyledText extends StatelessWidget {
  const StyledText(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Text(
      text,
      style: GoogleFonts.kanit(
        textStyle: textStyle?.copyWith(color: color ?? textStyle.color),
      ),
    );
  }
}

class StyledTextSmall extends StatelessWidget {
  const StyledTextSmall(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Text(
      text,
      style: GoogleFonts.kanit(
        textStyle: textStyle?.copyWith(color: color ?? textStyle.color),
      ),
    );
  }
}

class StyledTextMedium extends StatelessWidget {
  const StyledTextMedium(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Text(
      text,
      style: GoogleFonts.kanit(
        textStyle: textStyle?.copyWith(color: color ?? textStyle.color),
      ),
    );
  }
}

class StyledTextLarge extends StatelessWidget {
  const StyledTextLarge(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    return Text(
      text,
      style: GoogleFonts.kanit(
        textStyle: textStyle?.copyWith(color: color ?? textStyle.color),
      ),
    );
  }
}

class StyledHeading extends StatelessWidget {
  const StyledHeading(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.eduNswActFoundation(
        fontSize: 24,
        color: color ?? AppColors.titleColor,
        fontWeight: FontWeight.bold,
        letterSpacing: 3.5,
      ),
    );
  }
}

class StyledHeadingSmall extends StatelessWidget {
  const StyledHeadingSmall(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headlineSmall;
    return Text(
      text,
      style: GoogleFonts.kanit(
        textStyle: textStyle?.copyWith(color: color ?? textStyle.color),
      ),
    );
  }
}

class StyledHeadingMedium extends StatelessWidget {
  const StyledHeadingMedium(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headlineMedium;
    return Text(
      text,
      style: GoogleFonts.kanit(
        textStyle: textStyle?.copyWith(color: color ?? textStyle.color),
      ),
    );
  }
}

class StyledHeadingLarge extends StatelessWidget {
  const StyledHeadingLarge(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headlineLarge;
    return Text(
      text,
      style: GoogleFonts.kanit(
        textStyle: textStyle?.copyWith(color: color ?? textStyle.color),
      ),
    );
  }
}

class StyledTitleSmall extends StatelessWidget {
  const StyledTitleSmall(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleSmall;
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.kanit(
        textStyle: textStyle?.copyWith(color: color ?? textStyle.color),
      ),
    );
  }
}

class StyledTitleMedium extends StatelessWidget {
  const StyledTitleMedium(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.kanit(
        textStyle: textStyle?.copyWith(color: color ?? textStyle.color),
      ),
    );
  }
}

class StyledTitleLarge extends StatelessWidget {
  const StyledTitleLarge(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge;
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.kanit(
        textStyle: textStyle?.copyWith(color: color ?? textStyle.color),
      ),
    );
  }
}

class StyledActionText extends StatelessWidget {
  const StyledActionText(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleSmall;
    return Text(
      text,
      style: GoogleFonts.eduNswActFoundation(
        textStyle: textStyle?.copyWith(color: color ?? textStyle.color),
      ),
    );
  }
}
