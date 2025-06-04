import 'package:flutter/material.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';

class UserHeading extends StatelessWidget {
  const UserHeading({
    required this.username,
    required this.selectedBackgroundOption,
    required this.selectedProfileOption,
    this.coverHeight = 200,
    this.profileHeight = 100,
  super.key});

  final String username;
  final String selectedBackgroundOption;
  final String selectedProfileOption;
  final double coverHeight;
  final double profileHeight;

    @override
  Widget build(BuildContext context) {
    final top = coverHeight - profileHeight / 2 - 25;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        buildCoverImage(),
        Positioned(
          top: top - 80,
          child: buildProfileImage(),
        ),
        Positioned(
          top: top + 20,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: StyledTitle(username.isNotEmpty ? username : 'Username'),
          ),
        )
      ],
    );
  }

  Widget buildCoverImage() => ClipPath(
        clipper: _BottomCurveClipper(),
        child: Container(
          color: Colors.white,
          child: Image.asset(
            'lib/assets/images/$selectedBackgroundOption',
            width: double.infinity,
            height: coverHeight - 60,
            fit: BoxFit.cover,
          ),
        ),
      );

  Widget buildProfileImage() => Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4.0,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            'lib/assets/images/$selectedProfileOption',
            width: profileHeight,
            height: profileHeight,
            fit: BoxFit.cover,
          ),
        ),
      );
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 1.3,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


