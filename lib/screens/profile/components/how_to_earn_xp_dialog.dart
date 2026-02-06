import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/gamification_constants.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Dialog explaining how users can earn experience points
///
/// Pulls values from PointRewards constants to ensure consistency.
class HowToEarnXPDialog extends StatelessWidget {
  const HowToEarnXPDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const HowToEarnXPDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.star,
                      color: AppTheme.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'How to Earn XP',
                      style: AppTheme.title(
                        size: 20,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppTheme.textLight),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Foraging section
              _buildSection(
                title: 'Foraging',
                icon: Icons.forest,
                iconColor: AppTheme.primary,
                items: [
                  _XPItem('Create a location marker', PointRewards.createMarker),
                  _XPItem('Update marker status', PointRewards.updateMarkerStatus),
                  _XPItem('Add photos to marker', PointRewards.addMarkerPhoto),
                  _XPItem('Comment on a marker', PointRewards.commentOnMarker),
                ],
              ),
              const SizedBox(height: 16),

              // Community section
              _buildSection(
                title: 'Community',
                icon: Icons.people,
                iconColor: AppTheme.accent,
                items: [
                  _XPItem('Share location with community', PointRewards.shareLocation),
                  _XPItem('Create a community post', PointRewards.createPost),
                  _XPItem('Like a post', PointRewards.likePost),
                  _XPItem('Comment on a post', PointRewards.commentOnPost),
                ],
              ),
              const SizedBox(height: 16),

              // Social section
              _buildSection(
                title: 'Social',
                icon: Icons.person_add,
                iconColor: Colors.blue,
                items: [
                  _XPItem('Add a friend', PointRewards.addFriend),
                ],
              ),
              const SizedBox(height: 16),

              // Recipes section
              _buildSection(
                title: 'Recipes',
                icon: Icons.restaurant_menu,
                iconColor: Colors.orange,
                items: [
                  _XPItem('Create a recipe', PointRewards.createRecipe),
                  _XPItem('Save a recipe', PointRewards.saveRecipe),
                  _XPItem('Share a recipe', PointRewards.shareRecipe),
                ],
              ),
              const SizedBox(height: 16),

              // Daily section
              _buildSection(
                title: 'Daily',
                icon: Icons.calendar_today,
                iconColor: AppTheme.success,
                items: [
                  _XPItem('Daily login', PointRewards.dailyLogin),
                  _XPItem('Streak bonus (per day)', PointRewards.streakBonus),
                ],
              ),
              const SizedBox(height: 20),

              // Achievements hint
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.secondary.withValues(alpha: 0.15),
                      AppTheme.accent.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: AppTheme.secondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Complete achievements for bonus points!',
                        style: AppTheme.body(
                          size: 13,
                          color: AppTheme.textWhite,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<_XPItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.body(
                size: 15,
                color: AppTheme.textWhite,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 26, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.action,
                  style: AppTheme.body(
                    size: 13,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+${item.points} pts',
                  style: AppTheme.caption(
                    size: 11,
                    color: AppTheme.success,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _XPItem {
  final String action;
  final int points;

  const _XPItem(this.action, this.points);
}
