import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/gamification_constants.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Display user's gamification stats with compact design
class StatsCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final levelTitle = LevelSystem.getLevelTitle(user.level);
    final progress = LevelSystem.progressToNextLevel(user.points);
    final pointsNeeded = LevelSystem.pointsNeededForNextLevel(user.points);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary,
              AppTheme.primaryLight,
            ],
          ),
          borderRadius: AppTheme.borderRadiusMedium,
          boxShadow: AppTheme.shadowMedium,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadiusMedium,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Level and trophy icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${user.level}',
                          style: AppTheme.display(
                            size: 22,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        Text(
                          levelTitle,
                          style: AppTheme.caption(
                            size: 11,
                            color: AppTheme.textWhite.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: AppTheme.borderRadiusSmall,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 24,
                      color: AppTheme.xp,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${user.points} XP',
                        style: AppTheme.caption(
                          size: 11,
                          color: AppTheme.textWhite,
                          weight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$pointsNeeded XP to next level',
                        style: AppTheme.caption(
                          size: 10,
                          color: AppTheme.textWhite.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: AppTheme.borderRadiusSmall,
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: AppTheme.borderRadiusSmall,
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: AppTheme.xpGradient,
                              borderRadius: AppTheme.borderRadiusSmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Stats row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.local_fire_department,
                      iconColor: AppTheme.streak,
                      value: '${user.currentStreak}',
                      label: 'Streak',
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    _StatItem(
                      icon: Icons.emoji_events,
                      iconColor: AppTheme.xp,
                      value: '${user.achievementCount}',
                      label: 'Badges',
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    _StatItem(
                      icon: Icons.stars,
                      iconColor: AppTheme.secondary,
                      value: '${user.points}',
                      label: 'Total XP',
                    ),
                  ],
                ),
              ),

              // Tap hint
              if (onTap != null) ...[
                const SizedBox(height: 6),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tap to view achievements',
                        style: AppTheme.caption(
                          size: 10,
                          color: AppTheme.textWhite.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: AppTheme.textWhite.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.stats(
            size: 14,
            color: AppTheme.textWhite,
          ),
        ),
        Text(
          label,
          style: AppTheme.caption(
            size: 9,
            color: AppTheme.textWhite.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
