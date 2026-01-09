/// Achievement model for gamification system
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon; // Asset path or icon name
  final int pointsReward;
  final AchievementCategory category;
  final AchievementTier tier;
  final Map<String, dynamic> requirement; // Flexible requirement data

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.pointsReward,
    required this.category,
    required this.tier,
    required this.requirement,
  });

  /// Check if user meets the requirement for this achievement
  bool isUnlocked(Map<String, int> activityStats) {
    final statKey = requirement['statKey'] as String?;
    final threshold = requirement['threshold'] as int?;

    if (statKey == null || threshold == null) return false;

    final currentValue = activityStats[statKey] ?? 0;
    return currentValue >= threshold;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'pointsReward': pointsReward,
      'category': category.name,
      'tier': tier.name,
      'requirement': requirement,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String,
      pointsReward: map['pointsReward'] as int,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => AchievementCategory.general,
      ),
      tier: AchievementTier.values.firstWhere(
        (e) => e.name == map['tier'],
        orElse: () => AchievementTier.bronze,
      ),
      requirement: Map<String, dynamic>.from(map['requirement'] as Map),
    );
  }
}

enum AchievementCategory {
  general,
  forage,
  social,
  recipe,
  exploration,
  streak,
}

enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}
