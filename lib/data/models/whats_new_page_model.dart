import 'package:flutter/material.dart';

/// A single item in the What's New list for a given version.
class WhatsNewItem {
  final String title;
  final String description;
  final IconData icon;

  const WhatsNewItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Version-keyed What's New content.
/// Add entries here when releasing a new version.
class WhatsNewContent {
  static const Map<String, List<WhatsNewItem>> releases = {
    '4.5.7': [
      WhatsNewItem(
        title: 'Push Notifications',
        description:
            'Get notified when someone likes your post, comments, or sends a friend request.',
        icon: Icons.notifications_active,
      ),
      WhatsNewItem(
        title: 'Friends & Forage Together',
        description:
            'Send friend requests, discover nearby foragers, and plan foraging trips together.',
        icon: Icons.people,
      ),
      WhatsNewItem(
        title: 'Community Feed Overhaul',
        description:
            'Redesigned community posts with better photos, likes, and comments.',
        icon: Icons.dynamic_feed,
      ),
      WhatsNewItem(
        title: 'Leaderboard Profiles',
        description:
            'Tap any user on the leaderboard to view their profile. Your rank is now highlighted.',
        icon: Icons.leaderboard,
      ),
      WhatsNewItem(
        title: 'Map & UI Improvements',
        description:
            'Improved map performance, bug fixes, and refreshed backgrounds across the app.',
        icon: Icons.map,
      ),
    ],
  };

  /// Get the What's New items for a specific version.
  static List<WhatsNewItem> forVersion(String version) {
    return releases[version] ?? [];
  }
}
