import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/data/models/notification_preferences.dart';

class UserModel {
  // Basic info
  final String uid;
  final String email;
  final String username;
  final String bio;
  final String profilePic;
  final String profileBackground;

  // Social
  final List<String> friends;
  final Map<String, String> friendRequests;
  final Map<String, String> sentFriendRequests;

  // Saved content
  final List<String> savedRecipes;
  final List<String> savedLocations;

  // Legacy stats
  final Map<String, int> forageStats;
  final Map<String, dynamic> preferences;

  // Timestamps
  final Timestamp createdAt;
  final Timestamp lastActive;

  // UI state (should be computed, not stored - kept for backwards compatibility)
  final bool isFriend;
  final bool hasPendingRequest;

  // GAMIFICATION - New fields
  final int points; // Total points earned
  final int level; // User level based on points
  final List<String> achievements; // List of achievement IDs unlocked
  final Map<String, int> activityStats; // Detailed stats for gamification
  final int currentStreak; // Current daily activity streak
  final int longestStreak; // Best streak ever achieved
  final DateTime?
      lastActivityDate; // Last time user was active (for streak tracking)

  // PREMIUM - New fields
  final String subscriptionTier; // 'free', 'premium', 'pro'
  final DateTime? subscriptionExpiry; // When premium expires
  final bool hasCompletedOnboarding; // Track if user has seen onboarding

  // NOTIFICATIONS - New fields
  final NotificationPreferences notificationPreferences;

  // SOCIAL/FORAGING TOGETHER - New fields
  /// Whether the user is open to foraging with others
  final bool openToForage;

  /// User's foraging preferences/availability (e.g., "Weekends, mushrooms, beginner-friendly")
  final String? foragePreferences;

  /// Primary forage location - display string (e.g., "Portland, United States")
  /// If null, will be auto-set from user's first/most recent marker
  final String? primaryForageLocation;

  /// Primary forage location latitude (for distance calculations)
  final double? primaryForageLatitude;

  /// Primary forage location longitude (for distance calculations)
  final double? primaryForgeLongitude;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.bio = "",
    this.profilePic = 'profileImage1.jpg',
    this.profileBackground = 'backgroundProfileImage1.jpg',
    this.friends = const [],
    this.friendRequests = const {},
    this.sentFriendRequests = const {},
    this.savedRecipes = const [],
    this.savedLocations = const [],
    this.forageStats = const {},
    this.preferences = const {},
    required this.createdAt,
    required this.lastActive,
    this.isFriend = false,
    this.hasPendingRequest = false,
    // Gamification fields
    this.points = 0,
    this.level = 1,
    this.achievements = const [],
    this.activityStats = const {},
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    // Premium fields
    this.subscriptionTier = 'free',
    this.subscriptionExpiry,
    this.hasCompletedOnboarding = false,
    // Notification fields
    this.notificationPreferences = const NotificationPreferences(),
    // Social/Foraging together fields
    this.openToForage = false,
    this.foragePreferences,
    this.primaryForageLocation,
    this.primaryForageLatitude,
    this.primaryForgeLongitude,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Helper function to safely convert dynamic to Map<String, String>
    Map<String, String> safeStringMapConvert(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, String>.from(value);
      }
      return {};
    }

    // Helper function to safely convert dynamic to Map<String, int>
    Map<String, int> safeIntMapConvert(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, int>.from(value);
      }
      return {};
    }

    // Helper function to safely convert dynamic to List<String>
    List<String> safeStringListConvert(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return List<String>.from(value.whereType<String>());
      }
      return [];
    }

    // Helper function to get string value with fallback for empty strings
    String getStringValue(dynamic value, String fallback) {
      if (value == null) return fallback;
      final stringValue = value.toString().trim();
      return stringValue.isNotEmpty ? stringValue : fallback;
    }

    return UserModel(
      uid: doc.id,
      email: data['email']?.toString() ?? '',
      username: data['username']?.toString() ?? '',
      bio: data['bio']?.toString() ?? '',
      profilePic: getStringValue(data['profilePic'], 'profileImage1.jpg'),
      profileBackground: getStringValue(
          data['profileBackground'], 'backgroundProfileImage1.jpg'),
      friends: safeStringListConvert(data['friends']),
      friendRequests: safeStringMapConvert(data['friendRequests']),
      sentFriendRequests: safeStringMapConvert(data['sentFriendRequests']),
      savedRecipes: safeStringListConvert(data['savedRecipes']),
      savedLocations: safeStringListConvert(data['savedLocations']),
      forageStats: safeIntMapConvert(data['forageStats']),
      preferences: data['preferences'] is Map
          ? Map<String, dynamic>.from(data['preferences'])
          : {},
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : Timestamp.now(),
      lastActive: data['lastActive'] is Timestamp
          ? data['lastActive'] as Timestamp
          : Timestamp.now(),
      // Gamification fields (backwards compatible - default if missing)
      points: data['points'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      achievements: safeStringListConvert(data['achievements']),
      activityStats: safeIntMapConvert(data['activityStats']),
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      lastActivityDate: data['lastActivityDate'] != null
          ? (data['lastActivityDate'] as Timestamp).toDate()
          : null,
      // Premium fields (backwards compatible)
      subscriptionTier: data['subscriptionTier']?.toString() ?? 'free',
      subscriptionExpiry: data['subscriptionExpiry'] != null
          ? (data['subscriptionExpiry'] as Timestamp).toDate()
          : null,
      hasCompletedOnboarding: data['hasCompletedOnboarding'] as bool? ?? false,
      // Notification preferences (backwards compatible)
      notificationPreferences: NotificationPreferences.fromMap(
        data['notificationPreferences'] as Map<String, dynamic>?,
      ),
      // Social/Foraging together fields (backwards compatible)
      openToForage: data['openToForage'] as bool? ?? false,
      foragePreferences: data['foragePreferences'] as String?,
      primaryForageLocation: data['primaryForageLocation'] as String?,
      primaryForageLatitude: (data['primaryForageLatitude'] as num?)?.toDouble(),
      primaryForgeLongitude: (data['primaryForgeLongitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'bio': bio,
      'profilePic': profilePic,
      'profileBackground': profileBackground,
      'friends': friends,
      'friendRequests': friendRequests,
      'sentFriendRequests': sentFriendRequests,
      'savedRecipes': savedRecipes,
      'savedLocations': savedLocations,
      'forageStats': forageStats,
      'preferences': preferences,
      'createdAt': createdAt,
      'lastActive': lastActive,
      // Gamification fields
      'points': points,
      'level': level,
      'achievements': achievements,
      'activityStats': activityStats,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': lastActivityDate != null
          ? Timestamp.fromDate(lastActivityDate!)
          : null,
      // Premium fields
      'subscriptionTier': subscriptionTier,
      'subscriptionExpiry': subscriptionExpiry != null
          ? Timestamp.fromDate(subscriptionExpiry!)
          : null,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      // Notification preferences
      'notificationPreferences': notificationPreferences.toMap(),
      // Social/Foraging together fields
      'openToForage': openToForage,
      if (foragePreferences != null) 'foragePreferences': foragePreferences,
      if (primaryForageLocation != null)
        'primaryForageLocation': primaryForageLocation,
      if (primaryForageLatitude != null)
        'primaryForageLatitude': primaryForageLatitude,
      if (primaryForgeLongitude != null)
        'primaryForgeLongitude': primaryForgeLongitude,
    };
  }

  bool hasPendingRequestFrom(String userId) =>
      friendRequests.containsKey(userId) && friendRequests[userId] == 'pending';

  bool hasPendingSentRequestTo(String userId) =>
      sentFriendRequests.containsKey(userId) &&
      sentFriendRequests[userId] == 'pending';

  List<String> get pendingIncomingRequests => friendRequests.entries
      .where((e) => e.value == 'pending')
      .map((e) => e.key)
      .toList();

  List<String> get pendingSentRequests => sentFriendRequests.entries
      .where((e) => e.value == 'pending')
      .map((e) => e.key)
      .toList();

  // GAMIFICATION HELPERS

  /// Check if user is a premium subscriber
  bool get isPremium =>
      subscriptionTier != 'free' &&
      (subscriptionExpiry == null ||
          subscriptionExpiry!.isAfter(DateTime.now()));

  /// Check if user has completed onboarding
  bool get needsOnboarding => !hasCompletedOnboarding;

  /// Calculate points needed for next level
  int get pointsNeededForNextLevel {
    // Formula: level * 100 points per level
    final nextLevelPoints = level * 100;
    return nextLevelPoints - points;
  }

  /// Get progress to next level (0.0 to 1.0)
  double get progressToNextLevel {
    final currentLevelPoints = (level - 1) * 100;
    final nextLevelPoints = level * 100;
    final pointsInLevel = points - currentLevelPoints;
    final pointsNeeded = nextLevelPoints - currentLevelPoints;
    return (pointsInLevel / pointsNeeded).clamp(0.0, 1.0);
  }

  /// Check if user has a specific achievement
  bool hasAchievement(String achievementId) =>
      achievements.contains(achievementId);

  /// Get total number of achievements unlocked
  int get achievementCount => achievements.length;

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? bio,
    String? profilePic,
    String? profileBackground,
    List<String>? friends,
    Map<String, String>? friendRequests,
    Map<String, String>? sentFriendRequests,
    List<String>? savedRecipes,
    List<String>? savedLocations,
    Map<String, int>? forageStats,
    Map<String, dynamic>? preferences,
    Timestamp? createdAt,
    Timestamp? lastActive,
    bool? isFriend,
    bool? hasPendingRequest,
    // Gamification fields
    int? points,
    int? level,
    List<String>? achievements,
    Map<String, int>? activityStats,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    // Premium fields
    String? subscriptionTier,
    DateTime? subscriptionExpiry,
    bool? hasCompletedOnboarding,
    // Notification fields
    NotificationPreferences? notificationPreferences,
    // Social/Foraging together fields
    bool? openToForage,
    String? foragePreferences,
    String? primaryForageLocation,
    double? primaryForageLatitude,
    double? primaryForgeLongitude,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profilePic: profilePic ?? this.profilePic,
      profileBackground: profileBackground ?? this.profileBackground,
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      sentFriendRequests: sentFriendRequests ?? this.sentFriendRequests,
      savedRecipes: savedRecipes ?? this.savedRecipes,
      savedLocations: savedLocations ?? this.savedLocations,
      forageStats: forageStats ?? this.forageStats,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isFriend: isFriend ?? this.isFriend,
      hasPendingRequest: hasPendingRequest ?? this.hasPendingRequest,
      // Gamification
      points: points ?? this.points,
      level: level ?? this.level,
      achievements: achievements ?? this.achievements,
      activityStats: activityStats ?? this.activityStats,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      // Premium
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      // Notifications
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      // Social/Foraging together
      openToForage: openToForage ?? this.openToForage,
      foragePreferences: foragePreferences ?? this.foragePreferences,
      primaryForageLocation:
          primaryForageLocation ?? this.primaryForageLocation,
      primaryForageLatitude:
          primaryForageLatitude ?? this.primaryForageLatitude,
      primaryForgeLongitude:
          primaryForgeLongitude ?? this.primaryForgeLongitude,
    );
  }

  /// Check if user has a primary forage location set
  bool get hasPrimaryForageLocation =>
      primaryForageLocation != null &&
      primaryForageLatitude != null &&
      primaryForgeLongitude != null;
}

enum FriendRequestStatus { pending, accepted, rejected, cancelled }
