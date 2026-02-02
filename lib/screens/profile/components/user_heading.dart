import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class UserHeading extends StatelessWidget {
  const UserHeading({
    required this.username,
    required this.selectedBackgroundOption,
    required this.selectedProfileOption,
    required this.createdAt,
    required this.lastActive,
    this.coverHeight = 120,
    this.profileHeight = 50,
    super.key,
  });

  final String username;
  final String selectedBackgroundOption;
  final String selectedProfileOption;
  final double coverHeight;
  final double profileHeight;
  final Timestamp createdAt;
  final Timestamp lastActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: coverHeight,
      child: Stack(
        children: [
          // Full background image
          _buildCoverImage(),

          // Profile card in top left with opacity
          Positioned(
            top: 10,
            left: 10,
            child: _buildProfileCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    return Stack(
      children: [
        Image.asset(
          'lib/assets/images/$selectedBackgroundOption',
          width: double.infinity,
          height: coverHeight,
          fit: BoxFit.cover,
        ),
        // Subtle gradient for depth
        Container(
          width: double.infinity,
          height: coverHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.transparent,
                AppTheme.primary.withValues(alpha: 0.15),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile image
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.secondary, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                'lib/assets/images/$selectedProfileOption',
                width: profileHeight,
                height: profileHeight,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Username and member since
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                username.isNotEmpty ? username : 'Forager',
                style: AppTheme.heading(
                  size: 14,
                  color: AppTheme.textDark,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Since ${DateFormat('MMM yyyy').format(createdAt.toDate())}',
                style: AppTheme.caption(
                  size: 10,
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
