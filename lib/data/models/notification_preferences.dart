import 'package:cloud_firestore/cloud_firestore.dart';

/// User notification preferences for push notifications
///
/// Controls what types of notifications the user receives and on which device
class NotificationPreferences {
  final bool enabled; // Master toggle for all notifications
  final bool socialNotifications; // Friend requests, comments, likes
  final bool seasonalAlerts; // "Berries in season" reminders
  final bool locationReminders; // "Check this spot again" reminders
  final bool recipeNotifications; // New recipes using your foraged items
  final bool communityUpdates; // Trending locations, milestones
  final bool achievementNotifications; // Achievement unlocked
  final String? fcmToken; // Firebase Cloud Messaging device token
  final Timestamp? fcmTokenUpdatedAt; // When the token was last refreshed

  const NotificationPreferences({
    this.enabled = true,
    this.socialNotifications = true,
    this.seasonalAlerts = true,
    this.locationReminders = true,
    this.recipeNotifications = true,
    this.communityUpdates = false, // Opt-in to reduce noise
    this.achievementNotifications = true,
    this.fcmToken,
    this.fcmTokenUpdatedAt,
  });

  /// Create from Firestore data
  factory NotificationPreferences.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const NotificationPreferences();

    return NotificationPreferences(
      enabled: data['enabled'] as bool? ?? true,
      socialNotifications: data['socialNotifications'] as bool? ?? true,
      seasonalAlerts: data['seasonalAlerts'] as bool? ?? true,
      locationReminders: data['locationReminders'] as bool? ?? true,
      recipeNotifications: data['recipeNotifications'] as bool? ?? true,
      communityUpdates: data['communityUpdates'] as bool? ?? false,
      achievementNotifications: data['achievementNotifications'] as bool? ?? true,
      fcmToken: data['fcmToken'] as String?,
      fcmTokenUpdatedAt: data['fcmTokenUpdatedAt'] as Timestamp?,
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'socialNotifications': socialNotifications,
      'seasonalAlerts': seasonalAlerts,
      'locationReminders': locationReminders,
      'recipeNotifications': recipeNotifications,
      'communityUpdates': communityUpdates,
      'achievementNotifications': achievementNotifications,
      'fcmToken': fcmToken,
      'fcmTokenUpdatedAt': fcmTokenUpdatedAt,
    };
  }

  /// Check if any notifications are enabled
  bool get hasAnyEnabled {
    return enabled &&
        (socialNotifications ||
            seasonalAlerts ||
            locationReminders ||
            recipeNotifications ||
            communityUpdates ||
            achievementNotifications);
  }

  /// Copy with new values
  NotificationPreferences copyWith({
    bool? enabled,
    bool? socialNotifications,
    bool? seasonalAlerts,
    bool? locationReminders,
    bool? recipeNotifications,
    bool? communityUpdates,
    bool? achievementNotifications,
    String? fcmToken,
    Timestamp? fcmTokenUpdatedAt,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      socialNotifications: socialNotifications ?? this.socialNotifications,
      seasonalAlerts: seasonalAlerts ?? this.seasonalAlerts,
      locationReminders: locationReminders ?? this.locationReminders,
      recipeNotifications: recipeNotifications ?? this.recipeNotifications,
      communityUpdates: communityUpdates ?? this.communityUpdates,
      achievementNotifications: achievementNotifications ?? this.achievementNotifications,
      fcmToken: fcmToken ?? this.fcmToken,
      fcmTokenUpdatedAt: fcmTokenUpdatedAt ?? this.fcmTokenUpdatedAt,
    );
  }
}
