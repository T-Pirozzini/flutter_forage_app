import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/repositories/gamification_repository.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Show celebration notifications with modern design
class RewardNotification {
  /// Show points earned notification
  static void showPoints(
    BuildContext context, {
    required int points,
    String message = 'Points Earned!',
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.xp.withOpacity(0.2),
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: const Icon(
                Icons.stars,
                color: AppTheme.xp,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+$points XP',
                    style: AppTheme.title(
                      size: 16,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  Text(
                    message,
                    style: AppTheme.caption(
                      size: 12,
                      color: AppTheme.textWhite.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show level up celebration with modern design
  static void showLevelUp(
    BuildContext context, {
    required int newLevel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusXLarge,
        ),
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
            borderRadius: AppTheme.borderRadiusXLarge,
          ),
          padding: const EdgeInsets.all(AppTheme.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated trophy
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.space24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        size: 80,
                        color: AppTheme.xp,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.space24),
              Text(
                'LEVEL UP!',
                style: AppTheme.display(
                  size: 36,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space24,
                  vertical: AppTheme.space8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.xp.withOpacity(0.3),
                  borderRadius: AppTheme.borderRadiusRound,
                ),
                child: Text(
                  'Level $newLevel',
                  style: AppTheme.heading(
                    size: 28,
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textWhite,
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.space16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                    ),
                  ),
                  child: Text(
                    'Awesome!',
                    style: AppTheme.button(
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show achievement unlocked celebration
  static void showAchievementUnlocked(
    BuildContext context, {
    required GamificationResult result,
  }) {
    if (result.achievementsUnlocked.isEmpty) return;

    final achievement = result.achievementsUnlocked.first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusXLarge,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.secondaryGradient,
            borderRadius: AppTheme.borderRadiusXLarge,
          ),
          padding: const EdgeInsets.all(AppTheme.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge icon
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        size: 64,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.space24),
              Text(
                'ACHIEVEMENT UNLOCKED!',
                style: AppTheme.heading(
                  size: 20,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space16),
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: AppTheme.borderRadiusMedium,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      achievement.title,
                      style: AppTheme.title(
                        size: 20,
                        color: AppTheme.textWhite,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      achievement.description,
                      style: AppTheme.body(
                        size: 14,
                        color: AppTheme.textWhite.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                  vertical: AppTheme.space8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.xp.withOpacity(0.3),
                  borderRadius: AppTheme.borderRadiusRound,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars,
                      color: AppTheme.xp,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${achievement.pointsReward} XP',
                      style: AppTheme.stats(
                        size: 18,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ],
                ),
              ),
              if (result.achievementsUnlocked.length > 1) ...[
                const SizedBox(height: AppTheme.space12),
                Text(
                  '+${result.achievementsUnlocked.length - 1} more achievement${result.achievementsUnlocked.length > 2 ? 's' : ''}!',
                  style: AppTheme.caption(
                    color: AppTheme.textWhite.withOpacity(0.7),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.space24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textWhite,
                    foregroundColor: AppTheme.secondary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.space16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                    ),
                  ),
                  child: Text(
                    'Awesome!',
                    style: AppTheme.button(
                      color: AppTheme.secondary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show all rewards from a GamificationResult
  static void showRewards(
    BuildContext context, {
    required GamificationResult result,
  }) {
    if (!result.hasRewards) return;

    // Show level up first (most important)
    if (result.leveledUp) {
      showLevelUp(context, newLevel: result.newLevel);

      // Delay showing achievements so they don't overlap
      if (result.achievementsUnlocked.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            showAchievementUnlocked(context, result: result);
          }
        });
      }
    }
    // Show achievements
    else if (result.achievementsUnlocked.isNotEmpty) {
      showAchievementUnlocked(context, result: result);
    }
    // Show just points
    else if (result.pointsEarned > 0) {
      showPoints(context, points: result.pointsEarned);
    }
  }
}
