import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:intl/intl.dart';

class UserHeading extends StatelessWidget {
  const UserHeading(
      {required this.username,
      required this.selectedBackgroundOption,
      required this.selectedProfileOption,
      required this.createdAt,
      required this.lastActive,
      this.coverHeight = 200,
      this.profileHeight = 100,
      super.key});

  final String username;
  final String selectedBackgroundOption;
  final String selectedProfileOption;
  final double coverHeight;
  final double profileHeight;
  final Timestamp createdAt;
  final Timestamp lastActive;

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
          top: top + 45,
          child: StyledHeading(username.isNotEmpty ? username : 'Username'),
        ),
        Positioned(
          top: 20,
          left: 20,
          child: Container(
              color: AppColors.primaryAccent.withValues(alpha: .8),
              child: Column(
                children: [
                  StyledTextSmall("Member Since"),
                  StyledTextSmall(
                      DateFormat('MMM yyyy').format(createdAt.toDate())),
                ],
              )),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Container(
              color: AppColors.primaryAccent.withValues(alpha: .8),
              child: Column(
                children: [
                  StyledTextSmall("Last Active"),
                  StyledTextSmall(
                      DateFormat('MMM yyyy').format(lastActive.toDate())),
                ],
              )),
        ),
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
