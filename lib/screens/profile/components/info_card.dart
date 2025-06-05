import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onTap;
  final IconData? icon;

  const InfoCard({
    Key? key,
    required this.title,
    required this.count,
    this.onTap,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon ?? _getDefaultIcon(title),
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '$count ${_getCountLabel(title)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.deepOrange,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to get appropriate icon based on title
  IconData _getDefaultIcon(String title) {
    switch (title.toLowerCase()) {
      case 'your locations':
        return Icons.location_on;
      case 'community locations':
        return Icons.bookmark;
      case 'friends locations':
        return Icons.group;
      case 'friend requests':
        return Icons.person_add;
      default:
        return Icons.info_outline;
    }
  }

  // Helper to get appropriate count label
  String _getCountLabel(String title) {
    switch (title.toLowerCase()) {
      case 'your locations':
        return 'saved';
      case 'community locations':
        return 'bookmarked';
      case 'friends locations':
        return 'friends';
      case 'friend requests':
        return 'requests';
      default:
        return '';
    }
  }
}
