import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/data/models/achievement.dart';
import 'package:flutter_forager_app/data/models/gamification_constants.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/data/repositories/user_repository.dart';

/// Repository for managing gamification features
///
/// Handles:
/// - Points awarding and tracking
/// - Level progression
/// - Achievement unlocking
/// - Streak tracking
/// - Leaderboards
class GamificationRepository {
  final UserRepository userRepository;

  GamificationRepository({required this.userRepository});

  // ============================================================================
  // POINTS SYSTEM
  // ============================================================================

  /// Award points to a user for completing an action
  /// Returns the new total points and any achievements unlocked
  Future<GamificationResult> awardPoints({
    required String userId,
    required int points,
    required String activityStatKey,
  }) async {
    final user = await userRepository.getById(userId);
    if (user == null) {
      throw Exception('User not found');
    }

    // Calculate new points and level
    final newPoints = user.points + points;
    final newLevel = LevelSystem.calculateLevel(newPoints);
    final leveledUp = newLevel > user.level;

    // Update activity stats
    final newActivityStats = Map<String, int>.from(user.activityStats);
    newActivityStats[activityStatKey] =
        (newActivityStats[activityStatKey] ?? 0) + 1;

    // Check for newly unlocked achievements
    final newlyUnlocked = await _checkAchievements(
      user,
      newActivityStats,
    );

    // Add achievement points
    int achievementPoints = 0;
    for (final achievement in newlyUnlocked) {
      achievementPoints += achievement.pointsReward;
    }

    final finalPoints = newPoints + achievementPoints;
    final finalLevel = LevelSystem.calculateLevel(finalPoints);

    // Update user in Firestore
    await userRepository.update(userId, {
      'points': finalPoints,
      'level': finalLevel,
      'activityStats': newActivityStats,
      'achievements': user.achievements +
          newlyUnlocked.map((a) => a.id).toList(),
      'lastActive': Timestamp.now(),
    });

    return GamificationResult(
      pointsEarned: points,
      achievementPointsEarned: achievementPoints,
      totalPoints: finalPoints,
      newLevel: finalLevel,
      leveledUp: leveledUp,
      achievementsUnlocked: newlyUnlocked,
    );
  }

  /// Check for newly unlocked achievements
  Future<List<Achievement>> _checkAchievements(
    UserModel user,
    Map<String, int> newActivityStats,
  ) async {
    final unlocked = <Achievement>[];

    // Add current streak to stats for achievement checking
    final statsWithStreak = Map<String, int>.from(newActivityStats);
    statsWithStreak['currentStreak'] = user.currentStreak;

    for (final achievement in Achievements.all) {
      // Skip if already unlocked
      if (user.achievements.contains(achievement.id)) continue;

      // Check if now unlocked
      if (achievement.isUnlocked(statsWithStreak)) {
        unlocked.add(achievement);
      }
    }

    return unlocked;
  }

  // ============================================================================
  // STREAK SYSTEM
  // ============================================================================

  /// Update user's daily streak
  /// Call this when user performs any activity
  Future<StreakResult> updateStreak(String userId) async {
    final user = await userRepository.getById(userId);
    if (user == null) {
      throw Exception('User not found');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? lastActivityDay;
    if (user.lastActivityDate != null) {
      final last = user.lastActivityDate!;
      lastActivityDay = DateTime(last.year, last.month, last.day);
    }

    int newStreak = user.currentStreak;
    int pointsEarned = 0;
    bool streakIncreased = false;
    bool streakBroken = false;

    if (lastActivityDay == null) {
      // First activity ever
      newStreak = 1;
      pointsEarned = PointRewards.dailyLogin;
      streakIncreased = true;
    } else if (lastActivityDay.isBefore(today)) {
      // Activity on a new day
      final daysSinceLastActivity = today.difference(lastActivityDay).inDays;

      if (daysSinceLastActivity == 1) {
        // Consecutive day - increase streak
        newStreak = user.currentStreak + 1;
        pointsEarned = PointRewards.dailyLogin + PointRewards.streakBonus;
        streakIncreased = true;
      } else {
        // Streak broken - restart
        newStreak = 1;
        pointsEarned = PointRewards.dailyLogin;
        streakBroken = true;
      }

      final newLongestStreak = newStreak > user.longestStreak
          ? newStreak
          : user.longestStreak;

      // Update user
      await userRepository.update(userId, {
        'currentStreak': newStreak,
        'longestStreak': newLongestStreak,
        'lastActivityDate': Timestamp.fromDate(now),
      });

      // Award points for new day activity
      if (pointsEarned > 0) {
        await awardPoints(
          userId: userId,
          points: pointsEarned,
          activityStatKey: ActivityStats.daysActive,
        );
      }
    }
    // If same day, don't change streak

    return StreakResult(
      currentStreak: newStreak,
      longestStreak: user.longestStreak,
      streakIncreased: streakIncreased,
      streakBroken: streakBroken,
      pointsEarned: pointsEarned,
    );
  }

  // ============================================================================
  // LEADERBOARD
  // ============================================================================

  /// Get top users by points (only users who have opted in to leaderboard)
  /// Note: Users without points/showOnLeaderboard fields get defaults (0, true)
  Future<List<UserModel>> getLeaderboard({
    int limit = 50,
  }) async {
    try {
      // Fetch all users without orderBy (since some may not have points field)
      // Then sort and filter client-side
      final snapshot = await userRepository.firestoreService
          .collection(userRepository.collectionPath)
          .get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.showOnLeaderboard) // Filter out opted-out users
          .toList();

      // Sort by points descending (client-side)
      users.sort((a, b) => b.points.compareTo(a.points));

      // Return top N users
      return users.take(limit).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's leaderboard rank
  Future<int> getUserRank(String userId) async {
    try {
      final user = await userRepository.getById(userId);
      if (user == null) return 0;

      // Count users with more points
      final snapshot = await userRepository.firestoreService
          .collection(userRepository.collectionPath)
          .where('points', isGreaterThan: user.points)
          .get();

      return snapshot.docs.length + 1;
    } catch (e) {
      rethrow;
    }
  }

  /// Get friends leaderboard
  Future<List<UserModel>> getFriendsLeaderboard(String userId) async {
    try {
      final user = await userRepository.getById(userId);
      if (user == null) return [];

      final friendsList = user.friends;
      if (friendsList.isEmpty) return [];

      // Firestore 'in' query limit is 10, so chunk the requests
      final friends = <UserModel>[];

      for (var i = 0; i < friendsList.length; i += 10) {
        final chunk = friendsList.skip(i).take(10).toList();
        final snapshot = await userRepository.firestoreService
            .collection(userRepository.collectionPath)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        friends.addAll(
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)),
        );
      }

      // Sort by points
      friends.sort((a, b) => b.points.compareTo(a.points));

      return friends;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // ACHIEVEMENTS
  // ============================================================================

  /// Get all achievements with unlock status for a user
  Future<List<AchievementStatus>> getUserAchievements(String userId) async {
    final user = await userRepository.getById(userId);
    if (user == null) return [];

    return Achievements.all.map((achievement) {
      final isUnlocked = user.achievements.contains(achievement.id);
      final statsWithStreak = Map<String, int>.from(user.activityStats);
      statsWithStreak['currentStreak'] = user.currentStreak;

      return AchievementStatus(
        achievement: achievement,
        isUnlocked: isUnlocked,
        progress: _calculateAchievementProgress(
          achievement,
          statsWithStreak,
        ),
      );
    }).toList();
  }

  /// Calculate progress towards an achievement (0.0 to 1.0)
  double _calculateAchievementProgress(
    Achievement achievement,
    Map<String, int> stats,
  ) {
    final statKey = achievement.requirement['statKey'] as String?;
    final threshold = achievement.requirement['threshold'] as int?;

    if (statKey == null || threshold == null) return 0.0;

    final current = stats[statKey] ?? 0;
    return (current / threshold).clamp(0.0, 1.0);
  }
}

// ============================================================================
// RESULT CLASSES
// ============================================================================

/// Result of awarding points
class GamificationResult {
  final int pointsEarned;
  final int achievementPointsEarned;
  final int totalPoints;
  final int newLevel;
  final bool leveledUp;
  final List<Achievement> achievementsUnlocked;

  GamificationResult({
    required this.pointsEarned,
    required this.achievementPointsEarned,
    required this.totalPoints,
    required this.newLevel,
    required this.leveledUp,
    required this.achievementsUnlocked,
  });

  bool get hasRewards =>
      pointsEarned > 0 ||
      achievementPointsEarned > 0 ||
      leveledUp ||
      achievementsUnlocked.isNotEmpty;
}

/// Result of streak update
class StreakResult {
  final int currentStreak;
  final int longestStreak;
  final bool streakIncreased;
  final bool streakBroken;
  final int pointsEarned;

  StreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.streakIncreased,
    required this.streakBroken,
    required this.pointsEarned,
  });
}

/// Achievement with unlock status
class AchievementStatus {
  final Achievement achievement;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0

  AchievementStatus({
    required this.achievement,
    required this.isUnlocked,
    required this.progress,
  });
}
