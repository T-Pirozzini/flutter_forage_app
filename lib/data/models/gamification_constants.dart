import 'package:flutter_forager_app/data/models/achievement.dart';

/// Points awarded for various actions
class PointRewards {
  // Foraging actions
  static const int createMarker = 10;
  static const int updateMarkerStatus = 5;
  static const int addMarkerPhoto = 5;
  static const int commentOnMarker = 3;

  // Social actions
  static const int addFriend = 10;
  static const int shareLocation = 15;
  static const int likePost = 2;
  static const int commentOnPost = 5;
  static const int createPost = 10;

  // Recipe actions
  static const int createRecipe = 15;
  static const int saveRecipe = 3;
  static const int shareRecipe = 10;

  // Daily engagement
  static const int dailyLogin = 5;
  static const int streakBonus = 10; // Extra points for maintaining streak
}

/// Activity stat keys for tracking
class ActivityStats {
  static const String markersCreated = 'markersCreated';
  static const String markersUpdated = 'markersUpdated';
  static const String photosAdded = 'photosAdded';
  static const String commentsPosted = 'commentsPosted';
  static const String friendsAdded = 'friendsAdded';
  static const String locationsShared = 'locationsShared';
  static const String postsLiked = 'postsLiked';
  static const String postsCreated = 'postsCreated';
  static const String recipesCreated = 'recipesCreated';
  static const String recipesSaved = 'recipesSaved';
  static const String recipesShared = 'recipesShared';
  static const String daysActive = 'daysActive';
}

/// Predefined achievements
class Achievements {
  static final List<Achievement> all = [
    // === FORAGING ACHIEVEMENTS ===
    Achievement(
      id: 'first_find',
      title: 'First Find',
      description: 'Create your first forage location',
      icon: 'eco',
      pointsReward: 25,
      category: AchievementCategory.forage,
      tier: AchievementTier.bronze,
      requirement: {'statKey': ActivityStats.markersCreated, 'threshold': 1},
    ),
    Achievement(
      id: 'eager_forager',
      title: 'Eager Forager',
      description: 'Create 10 forage locations',
      icon: 'eco',
      pointsReward: 50,
      category: AchievementCategory.forage,
      tier: AchievementTier.silver,
      requirement: {'statKey': ActivityStats.markersCreated, 'threshold': 10},
    ),
    Achievement(
      id: 'expert_forager',
      title: 'Expert Forager',
      description: 'Create 25 forage locations',
      icon: 'eco',
      pointsReward: 100,
      category: AchievementCategory.forage,
      tier: AchievementTier.gold,
      requirement: {'statKey': ActivityStats.markersCreated, 'threshold': 25},
    ),
    Achievement(
      id: 'master_forager',
      title: 'Master Forager',
      description: 'Create 50 forage locations',
      icon: 'eco',
      pointsReward: 250,
      category: AchievementCategory.forage,
      tier: AchievementTier.platinum,
      requirement: {'statKey': ActivityStats.markersCreated, 'threshold': 50},
    ),
    Achievement(
      id: 'legendary_forager',
      title: 'Legendary Forager',
      description: 'Create 100 forage locations',
      icon: 'eco',
      pointsReward: 500,
      category: AchievementCategory.forage,
      tier: AchievementTier.diamond,
      requirement: {'statKey': ActivityStats.markersCreated, 'threshold': 100},
    ),

    // === SOCIAL ACHIEVEMENTS ===
    Achievement(
      id: 'friendly',
      title: 'Friendly Forager',
      description: 'Add your first friend',
      icon: 'person_add',
      pointsReward: 25,
      category: AchievementCategory.social,
      tier: AchievementTier.bronze,
      requirement: {'statKey': ActivityStats.friendsAdded, 'threshold': 1},
    ),
    Achievement(
      id: 'social_butterfly',
      title: 'Social Butterfly',
      description: 'Add 10 friends',
      icon: 'group',
      pointsReward: 75,
      category: AchievementCategory.social,
      tier: AchievementTier.silver,
      requirement: {'statKey': ActivityStats.friendsAdded, 'threshold': 10},
    ),
    Achievement(
      id: 'community_builder',
      title: 'Community Builder',
      description: 'Add 25 friends',
      icon: 'groups',
      pointsReward: 150,
      category: AchievementCategory.social,
      tier: AchievementTier.gold,
      requirement: {'statKey': ActivityStats.friendsAdded, 'threshold': 25},
    ),
    Achievement(
      id: 'sharing_is_caring',
      title: 'Sharing is Caring',
      description: 'Share 5 locations with the community',
      icon: 'share',
      pointsReward: 100,
      category: AchievementCategory.social,
      tier: AchievementTier.silver,
      requirement: {'statKey': ActivityStats.locationsShared, 'threshold': 5},
    ),
    Achievement(
      id: 'generous_forager',
      title: 'Generous Forager',
      description: 'Share 25 locations with the community',
      icon: 'share',
      pointsReward: 250,
      category: AchievementCategory.social,
      tier: AchievementTier.gold,
      requirement: {'statKey': ActivityStats.locationsShared, 'threshold': 25},
    ),

    // === RECIPE ACHIEVEMENTS ===
    Achievement(
      id: 'home_chef',
      title: 'Home Chef',
      description: 'Create your first recipe',
      icon: 'restaurant',
      pointsReward: 25,
      category: AchievementCategory.recipe,
      tier: AchievementTier.bronze,
      requirement: {'statKey': ActivityStats.recipesCreated, 'threshold': 1},
    ),
    Achievement(
      id: 'recipe_collector',
      title: 'Recipe Collector',
      description: 'Save 10 recipes',
      icon: 'bookmark',
      pointsReward: 50,
      category: AchievementCategory.recipe,
      tier: AchievementTier.bronze,
      requirement: {'statKey': ActivityStats.recipesSaved, 'threshold': 10},
    ),
    Achievement(
      id: 'master_chef',
      title: 'Master Chef',
      description: 'Create 10 recipes',
      icon: 'restaurant_menu',
      pointsReward: 150,
      category: AchievementCategory.recipe,
      tier: AchievementTier.gold,
      requirement: {'statKey': ActivityStats.recipesCreated, 'threshold': 10},
    ),

    // === STREAK ACHIEVEMENTS ===
    Achievement(
      id: 'getting_started',
      title: 'Getting Started',
      description: 'Maintain a 3-day streak',
      icon: 'local_fire_department',
      pointsReward: 50,
      category: AchievementCategory.streak,
      tier: AchievementTier.bronze,
      requirement: {'statKey': 'currentStreak', 'threshold': 3},
    ),
    Achievement(
      id: 'dedicated',
      title: 'Dedicated Forager',
      description: 'Maintain a 7-day streak',
      icon: 'local_fire_department',
      pointsReward: 100,
      category: AchievementCategory.streak,
      tier: AchievementTier.silver,
      requirement: {'statKey': 'currentStreak', 'threshold': 7},
    ),
    Achievement(
      id: 'committed',
      title: 'Committed Forager',
      description: 'Maintain a 30-day streak',
      icon: 'local_fire_department',
      pointsReward: 250,
      category: AchievementCategory.streak,
      tier: AchievementTier.gold,
      requirement: {'statKey': 'currentStreak', 'threshold': 30},
    ),
    Achievement(
      id: 'unstoppable',
      title: 'Unstoppable',
      description: 'Maintain a 100-day streak',
      icon: 'local_fire_department',
      pointsReward: 500,
      category: AchievementCategory.streak,
      tier: AchievementTier.diamond,
      requirement: {'statKey': 'currentStreak', 'threshold': 100},
    ),

    // === ENGAGEMENT ACHIEVEMENTS ===
    Achievement(
      id: 'helpful',
      title: 'Helpful Forager',
      description: 'Post 10 comments',
      icon: 'comment',
      pointsReward: 50,
      category: AchievementCategory.general,
      tier: AchievementTier.bronze,
      requirement: {'statKey': ActivityStats.commentsPosted, 'threshold': 10},
    ),
    Achievement(
      id: 'photographer',
      title: 'Photographer',
      description: 'Add 25 photos to locations',
      icon: 'photo_camera',
      pointsReward: 100,
      category: AchievementCategory.exploration,
      tier: AchievementTier.silver,
      requirement: {'statKey': ActivityStats.photosAdded, 'threshold': 25},
    ),
  ];

  /// Get achievement by ID
  static Achievement? getById(String id) {
    try {
      return all.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get achievements by category
  static List<Achievement> getByCategory(AchievementCategory category) {
    return all.where((achievement) => achievement.category == category).toList();
  }

  /// Get achievements by tier
  static List<Achievement> getByTier(AchievementTier tier) {
    return all.where((achievement) => achievement.tier == tier).toList();
  }
}

/// Level thresholds
class LevelSystem {
  /// Calculate level from points
  static int calculateLevel(int points) {
    // Simple formula: 100 points per level
    return (points ~/ 100) + 1;
  }

  /// Calculate points needed for specific level
  static int pointsForLevel(int level) {
    return (level - 1) * 100;
  }

  /// Calculate points needed for next level
  static int pointsNeededForNextLevel(int currentPoints) {
    final currentLevel = calculateLevel(currentPoints);
    final nextLevelPoints = pointsForLevel(currentLevel + 1);
    return nextLevelPoints - currentPoints;
  }

  /// Get progress to next level (0.0 to 1.0)
  static double progressToNextLevel(int currentPoints) {
    final currentLevel = calculateLevel(currentPoints);
    final currentLevelPoints = pointsForLevel(currentLevel);
    final nextLevelPoints = pointsForLevel(currentLevel + 1);
    final pointsInLevel = currentPoints - currentLevelPoints;
    final pointsNeeded = nextLevelPoints - currentLevelPoints;
    return (pointsInLevel / pointsNeeded).clamp(0.0, 1.0);
  }

  /// Get level title
  static String getLevelTitle(int level) {
    if (level >= 50) return 'Legendary Forager';
    if (level >= 40) return 'Master Forager';
    if (level >= 30) return 'Expert Forager';
    if (level >= 20) return 'Experienced Forager';
    if (level >= 10) return 'Skilled Forager';
    if (level >= 5) return 'Eager Forager';
    return 'Novice Forager';
  }
}
