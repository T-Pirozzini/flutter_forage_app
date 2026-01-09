# Gamification Integration Guide

This guide shows how to integrate the gamification system into your existing app features.

## Overview

The gamification system awards points, tracks achievements, manages streaks, and provides leaderboards to boost user engagement.

## Quick Start

### 1. Import the Helper

```dart
import 'package:flutter_forager_app/shared/gamification/gamification_helper.dart';
```

### 2. Award Points for Actions

Use the `GamificationHelper` to award points when users perform actions:

```dart
// In a ConsumerWidget or ConsumerStatefulWidget
await GamificationHelper.awardMarkerCreated(
  context: context,
  ref: ref,
  userId: currentUser.email!,
);
```

## Integration Examples

### Example 1: Creating a Forage Location

**Before:**
```dart
Future<void> _createMarker() async {
  // Create marker in Firestore
  await markerRepo.create(marker);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Location created!')),
  );
}
```

**After:**
```dart
Future<void> _createMarker() async {
  // Create marker in Firestore
  await markerRepo.create(marker);

  // Award points for creating marker
  await GamificationHelper.awardMarkerCreated(
    context: context,
    ref: ref,
    userId: currentUser.email!,
  );
}
```

### Example 2: Adding a Friend

**Before:**
```dart
Future<void> _acceptFriendRequest(String requesterId) async {
  await userRepo.acceptFriendRequest(userId, requesterId);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Friend request accepted!')),
  );
}
```

**After:**
```dart
Future<void> _acceptFriendRequest(String requesterId) async {
  await userRepo.acceptFriendRequest(userId, requesterId);

  // Award points for adding friend
  await GamificationHelper.awardFriendAdded(
    context: context,
    ref: ref,
    userId: currentUser.email!,
  );
}
```

### Example 3: Updating Streak on Login

Add this to your main app initialization or home page:

```dart
@override
void initState() {
  super.initState();

  // Update daily streak
  WidgetsBinding.instance.addPostFrameCallback((_) {
    GamificationHelper.updateStreak(
      context: context,
      ref: ref,
      userId: currentUser.email!,
    );
  });
}
```

## Available Helper Methods

### Foraging Actions
- `awardMarkerCreated()` - Creating a forage location (+10 XP)
- `awardMarkerStatusUpdate()` - Updating marker status (+5 XP)
- `awardPhotoAdded()` - Adding photo to marker (+5 XP)
- `awardMarkerComment()` - Commenting on marker (+3 XP)

### Social Actions
- `awardFriendAdded()` - Adding a friend (+10 XP)
- `awardLocationShared()` - Sharing location with community (+15 XP)
- `awardPostLiked()` - Liking a post (+2 XP)
- `awardPostComment()` - Commenting on post (+5 XP)
- `awardPostCreated()` - Creating a post (+10 XP)

### Recipe Actions
- `awardRecipeCreated()` - Creating a recipe (+15 XP)
- `awardRecipeSaved()` - Saving a recipe (+3 XP)
- `awardRecipeShared()` - Sharing a recipe (+10 XP)

### Streak Tracking
- `updateStreak()` - Update daily activity streak

## Points & Levels

- **Points (XP)**: Earned by completing actions
- **Levels**: Automatically calculated (100 XP per level)
- **Achievements**: Unlocked based on activity milestones
- **Streaks**: Daily login bonuses (+5 XP daily, +10 XP streak bonus)

## Level Titles

- Level 1-4: Novice Forager
- Level 5-9: Eager Forager
- Level 10-19: Skilled Forager
- Level 20-29: Experienced Forager
- Level 30-39: Expert Forager
- Level 40-49: Master Forager
- Level 50+: Legendary Forager

## Achievement Categories

1. **Foraging** - Creating and managing locations
2. **Social** - Friends and community
3. **Recipes** - Creating and sharing recipes
4. **Streaks** - Daily activity
5. **Exploration** - Photos and updates
6. **General** - Comments and engagement

## Best Practices

1. **Don't over-notify**: Set `showNotification: false` for small actions (likes, saves)
2. **Update streaks early**: Call `updateStreak()` in your home page or app initialization
3. **Use context.mounted**: Always check if widget is still mounted before showing notifications
4. **Silent failures**: Gamification errors won't disrupt the user experience
5. **Test incrementally**: Add gamification to one feature at a time

## UI Components

### StatsCard
Shows user's level, points, and progress:
```dart
StatsCard(
  user: userData,
  onTap: () => Navigator.push(...), // Navigate to achievements
)
```

### AchievementCard
Displays individual achievement with progress:
```dart
AchievementCard(
  achievementStatus: achievementStatus,
)
```

### Navigation
Add to drawer or app bar:
- **Achievements Page**: View all achievements with progress
- **Leaderboard Page**: Global and friends rankings

## Customization

### Adjust Point Rewards
Edit `lib/data/models/gamification_constants.dart`:
```dart
class PointRewards {
  static const int createMarker = 10; // Change this value
  // ... other rewards
}
```

### Add New Achievements
Add to `Achievements.all` list in `gamification_constants.dart`:
```dart
Achievement(
  id: 'unique_id',
  title: 'Achievement Title',
  description: 'Description of what to unlock',
  icon: 'icon_name', // Material icon name
  pointsReward: 50,
  category: AchievementCategory.forage,
  tier: AchievementTier.gold,
  requirement: {'statKey': ActivityStats.markersCreated, 'threshold': 5},
),
```

### Modify Level Formula
Edit `LevelSystem.calculateLevel()` in `gamification_constants.dart`:
```dart
static int calculateLevel(int points) {
  return (points ~/ 100) + 1; // 100 points per level
}
```

## Files Modified

When integrating gamification into existing features, you'll typically:

1. Import `gamification_helper.dart`
2. Add `await GamificationHelper.awardXXX()` after successful actions
3. (Optional) Update streak in app initialization

No changes needed to existing repository or data models!
