import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/gamification_constants.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Display user's gamification stats with modern design
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
          borderRadius: AppTheme.borderRadiusLarge,
          boxShadow: AppTheme.shadowMedium,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadiusLarge,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(AppTheme.space24),
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
                            size: 32,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          levelTitle,
                          style: AppTheme.caption(
                            color: AppTheme.textWhite.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: AppTheme.borderRadiusMedium,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 40,
                      color: AppTheme.xp,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),

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
                          color: AppTheme.textWhite,
                          weight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$pointsNeeded XP to next level',
                        style: AppTheme.caption(
                          size: 12,
                          color: AppTheme.textWhite.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space8),
                  ClipRRect(
                    borderRadius: AppTheme.borderRadiusSmall,
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: AppTheme.borderRadiusSmall,
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 8,
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
              const SizedBox(height: AppTheme.space24),

              // Stats row
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: AppTheme.borderRadiusMedium,
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
                      height: 40,
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
                      height: 40,
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
                const SizedBox(height: AppTheme.space16),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tap to view achievements',
                        style: AppTheme.caption(
                          size: 12,
                          color: AppTheme.textWhite.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
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
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.stats(
            size: 20,
            color: AppTheme.textWhite,
          ),
        ),
        Text(
          label,
          style: AppTheme.caption(
            size: 11,
            color: AppTheme.textWhite.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
