import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/data/models/gamification_constants.dart';
import 'package:flutter_forager_app/data/repositories/gamification_repository.dart';
import 'package:flutter_forager_app/providers/gamification/gamification_provider.dart';
import 'package:flutter_forager_app/shared/gamification/reward_notification.dart';

/// Helper class to easily award points throughout the app
class GamificationHelper {
  /// Award points for creating a marker
  static Future<void> awardMarkerCreated({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    bool showNotification = true,
  }) async {
    return _awardPoints(
      context: context,
      ref: ref,
      userId: userId,
      points: PointRewards.createMarker,
      activityStatKey: ActivityStats.markersCreated,
      message: 'Location created!',
      showNotification: showNotification,
    );
  }

  /// Award points for updating marker status
  static Future<void> awardMarkerStatusUpdate({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    bool showNotification = true,
  }) async {
    return _awardPoints(
      context: context,
      ref: ref,
      userId: userId,
      points: PointRewards.updateMarkerStatus,
      activityStatKey: ActivityStats.markersUpdated,
      message: 'Status updated!',
      showNotification: showNotification,
    );
  }

  /// Award points for adding photo to marker
  static Future<void> awardPhotoAdded({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    bool showNotification = true,
  }) async {
    return _awardPoints(
      context: context,
      ref: ref,
      userId: userId,
      points: PointRewards.addMarkerPhoto,
      activityStatKey: ActivityStats.photosAdded,
      message: 'Photo added!',
      showNotification: showNotification,
    );
  }

  /// Award points for commenting on marker
  static Future<void> awardMarkerComment({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    bool showNotification = true,
  }) async {
    return _awardPoints(
      context: context,
      ref: ref,
      userId: userId,
      points: PointRewards.commentOnMarker,
      activityStatKey: ActivityStats.commentsPosted,
      message: 'Comment posted!',
      showNotification: showNotification,
    );
  }

  /// Award points for adding a friend
  static Future<void> awardFriendAdded({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    bool showNotification = true,
  }) async {
    return _awardPoints(
      context: context,
      ref: ref,
      userId: userId,
      points: PointRewards.addFriend,
      activityStatKey: ActivityStats.friendsAdded,
      message: 'Friend added!',
      showNotification: showNotification,
    );
  }

  /// Award points for sharing location with community
  static Future<void> awardLocationShared({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    bool showNotification = true,
  }) async {
    return _awardPoints(
      context: context,
      ref: ref,
      userId: userId,
      points: PointRewards.shareLocation,
      activityStatKey: ActivityStats.locationsShared,
      message: 'Location shared with community!',
      showNotification: showNotification,
    );
  }

  /// Award points for liking a post
  static Future<void> awardPostLiked({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    bool showNotification = false, // Don't show for small actions
  }) async {
    return _awardPoints(
      context: context,
      ref: ref,
      userId: userId,
      points: PointRewards.likePost,
      activityStatKey: ActivityStats.postsLiked,
      message: 'Post liked!',
      showNotification: showNotification,
    );
  }

  /// Award points for commenting on post
  static Future<void> awardPostComment({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    bool showNotification = true,
  }) async {
    return _awardPoints(
      context: context,
      ref: ref,
      userId: userId,
      points: PointRewards.commentOnPost,
      activityStatKey: ActivityStats.commentsPosted,
      message: 'Comment posted!',
      showNotification: showNotification,
    );
  }

  /// Award points for creating a post
  static Future<void> awardPostCreated({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    bool showNotification = true,
  }) async {
    return _awardPoints(
      context: context,
      ref: ref,
      userId: userId,
      points: PointRewards.createPost,
      activityStatKey: ActivityStats.postsCreated,
      message: 'Post created!',
      showNotification: showNotification,
    );
  }

  /// Award points for creating a recipe
  static Future<void> awardRecipeCreated({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    bool showNotification = true,
  }) async {
    return _awardPoints(
      context: context,
      ref: ref,
      userId: userId,
      points: PointRewards.createRecipe,
      activityStatKey: ActivityStats.recipesCreated,
      message: 'Recipe created!',
      showNotification: showNotification,
    );
  }

  /// Award points for saving a recipe
  static Future<void> awardRecipeSaved({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    bool showNotification = false, // Don't show for small actions
  }) async {
    return _awardPoints(
      context: context,
      ref: ref,
      userId: userId,
      points: PointRewards.saveRecipe,
      activityStatKey: ActivityStats.recipesSaved,
      message: 'Recipe saved!',
      showNotification: showNotification,
    );
  }

  /// Award points for sharing a recipe
  static Future<void> awardRecipeShared({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    bool showNotification = true,
  }) async {
    return _awardPoints(
      context: context,
      ref: ref,
      userId: userId,
      points: PointRewards.shareRecipe,
      activityStatKey: ActivityStats.recipesShared,
      message: 'Recipe shared!',
      showNotification: showNotification,
    );
  }

  /// Update daily streak (call this on any user activity)
  static Future<void> updateStreak({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
  }) async {
    try {
      final gamificationRepo = ref.read(gamificationRepositoryProvider);
      final result = await gamificationRepo.updateStreak(userId);

      if (!context.mounted) return;

      // Show streak notification if increased
      if (result.streakIncreased && result.currentStreak > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '${result.currentStreak} Day Streak! 🔥',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.deepOrange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result.streakBroken) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Streak reset. Start a new one today!',
              style: TextStyle(fontSize: 14),
            ),
            backgroundColor: Colors.grey[700],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }

  /// Internal method to award points
  static Future<void> _awardPoints({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required int points,
    required String activityStatKey,
    required String message,
    required bool showNotification,
  }) async {
    try {
      final gamificationRepo = ref.read(gamificationRepositoryProvider);

      // Award points
      final result = await gamificationRepo.awardPoints(
        userId: userId,
        points: points,
        activityStatKey: activityStatKey,
      );

      if (!context.mounted) return;

      // Show rewards
      if (showNotification && result.hasRewards) {
        RewardNotification.showRewards(context, result: result);
      }
    } catch (e) {
      debugPrint('Error awarding points: $e');
      // Silently fail - don't disrupt user experience
    }
  }
}
