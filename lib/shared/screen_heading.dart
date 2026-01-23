import 'package:flutter/material.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

class ScreenHeading extends StatelessWidget {
  const ScreenHeading({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: AppTheme.surfaceLight, // Neutral instead of green tint
      alignment: Alignment.center,
      child: StyledHeading(title.toUpperCase()),
    );
  }
}
