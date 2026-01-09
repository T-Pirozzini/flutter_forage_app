import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/repositories/gamification_repository.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Display an achievement card with unlock status and progress
class AchievementCard extends StatelessWidget {
  final AchievementStatus achievementStatus;

  const AchievementCard({
    super.key,
    required this.achievementStatus,
  });

  Color _getTierColor() {
    switch (achievementStatus.achievement.tier.name) {
      case 'bronze':
        return Colors.brown;
      case 'silver':
        return Colors.grey;
      case 'gold':
        return Colors.amber;
      case 'platinum':
        return Colors.cyan;
      case 'diamond':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconData() {
    // Map string icon names to IconData
    final iconName = achievementStatus.achievement.icon;
    switch (iconName) {
      case 'eco':
        return Icons.eco;
      case 'person_add':
        return Icons.person_add;
      case 'group':
        return Icons.group;
      case 'groups':
        return Icons.groups;
      case 'share':
        return Icons.share;
      case 'restaurant':
        return Icons.restaurant;
      case 'bookmark':
        return Icons.bookmark;
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'comment':
        return Icons.comment;
      case 'photo_camera':
        return Icons.photo_camera;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievement = achievementStatus.achievement;
    final isUnlocked = achievementStatus.isUnlocked;
    final progress = achievementStatus.progress;
    final tierColor = _getTierColor();

    return Card(
      elevation: isUnlocked ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnlocked
            ? BorderSide(color: tierColor, width: 2)
            : BorderSide.none,
      ),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Achievement icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? tierColor.withOpacity(0.2)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(),
                  size: 32,
                  color: isUnlocked ? tierColor : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),

              // Achievement details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.title,
                            style: GoogleFonts.kanit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked
                                  ? AppColors.textColor
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        if (isUnlocked)
                          Icon(
                            Icons.check_circle,
                            color: tierColor,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Progress bar (only show if not unlocked)
                    if (!isUnlocked) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  tierColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Points reward (show when unlocked)
                      Row(
                        children: [
                          Icon(Icons.stars, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          StyledText(
                            '+${achievement.pointsReward} XP',
                            color: Colors.amber,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
