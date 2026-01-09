# 🎮 Gamification Quick Start

## What's Already Working

✅ **Daily Streak Tracking** - Runs automatically on app launch (HomePage)
✅ **Profile Stats** - Shows on user profile page
✅ **Achievements Page** - Navigate from drawer or stats card
✅ **Leaderboard Page** - Navigate from drawer
✅ **Celebration UI** - Level ups, achievements, point notifications

## Add Gamification in 3 Steps

### Step 1: Import the Helper
```dart
import 'package:flutter_forager_app/shared/gamification/gamification_helper.dart';
```

### Step 2: Make Your Widget a ConsumerWidget/ConsumerStatefulWidget
If not already using Riverpod:
```dart
// Before
class MyPage extends StatefulWidget { ... }

// After
class MyPage extends ConsumerStatefulWidget { ... }
class _MyPageState extends ConsumerState<MyPage> { ... }
```

### Step 3: Add ONE Line After Successful Actions
```dart
// After creating a marker
await GamificationHelper.awardMarkerCreated(
  context: context,
  ref: ref,
  userId: currentUser.email!,
);

// After accepting friend request
await GamificationHelper.awardFriendAdded(
  context: context,
  ref: ref,
  userId: currentUser.email!,
);

// After sharing to community
await GamificationHelper.awardLocationShared(
  context: context,
  ref: ref,
  userId: currentUser.email!,
);
```

## All Available Methods

### Foraging
```dart
GamificationHelper.awardMarkerCreated()        // +10 XP
GamificationHelper.awardMarkerStatusUpdate()   // +5 XP
GamificationHelper.awardPhotoAdded()           // +5 XP
GamificationHelper.awardMarkerComment()        // +3 XP
```

### Social
```dart
GamificationHelper.awardFriendAdded()          // +10 XP
GamificationHelper.awardLocationShared()       // +15 XP
GamificationHelper.awardPostLiked()            // +2 XP
GamificationHelper.awardPostComment()          // +5 XP
GamificationHelper.awardPostCreated()          // +10 XP
```

### Recipes
```dart
GamificationHelper.awardRecipeCreated()        // +15 XP
GamificationHelper.awardRecipeSaved()          // +3 XP
GamificationHelper.awardRecipeShared()         // +10 XP
```

## Priority Integration Targets

**Start with these for maximum impact:**

1. **Marker Creation** (forage_location_info_page.dart or map_page.dart)
2. **Friend Request Acceptance** (friend_request_page.dart)
3. **Location Sharing** (forage_location_info_page.dart - `_postToCommunity()`)
4. **Recipe Creation** (recipes page)

## Testing the System

### Test Achievements
1. Open app → Check streak notification
2. Create 1 location → "First Find" achievement (25 XP bonus)
3. Add 1 friend → "Friendly Forager" achievement (25 XP bonus)
4. Reach 100 XP → Level 2 celebration

### Test Leaderboard
1. Create some content to earn points
2. Open drawer → Leaderboard
3. Check your ranking
4. Invite friends to compete

### Test Streak
1. Use app today → See streak notification
2. Come back tomorrow → Streak increases
3. Skip a day → Streak resets

## Example Integration

**File**: `lib/screens/forage_locations/forage_location_info_page.dart`

**Find**:
```dart
Future<void> _postToCommunity() async {
  // ... existing code ...

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location shared with community!')),
    );
    Navigator.of(context).pop();
  }
}
```

**Add**:
```dart
Future<void> _postToCommunity() async {
  // ... existing code ...

  // Award points for sharing
  await GamificationHelper.awardLocationShared(
    context: context,
    ref: ref,
    userId: currentUser.email!,
  );

  if (mounted) {
    Navigator.of(context).pop();
  }
}
```

## Customization

### Turn Off Notifications
For small actions like "likes":
```dart
await GamificationHelper.awardPostLiked(
  context: context,
  ref: ref,
  userId: currentUser.email!,
  showNotification: false,  // Silent tracking
);
```

### Adjust Point Values
Edit `lib/data/models/gamification_constants.dart`:
```dart
class PointRewards {
  static const int createMarker = 15;  // Changed from 10
  static const int addFriend = 20;     // Changed from 10
  // ...
}
```

### Add New Achievement
Edit `Achievements.all` in `lib/data/models/gamification_constants.dart`:
```dart
Achievement(
  id: 'photo_pro',
  title: 'Photo Pro',
  description: 'Add 50 photos to locations',
  icon: 'photo_camera',
  pointsReward: 100,
  category: AchievementCategory.exploration,
  tier: AchievementTier.gold,
  requirement: {'statKey': ActivityStats.photosAdded, 'threshold': 50},
),
```

## Documentation

- **Full Details**: See `GAMIFICATION_IMPLEMENTATION_SUMMARY.md`
- **Integration Guide**: See `GAMIFICATION_INTEGRATION_GUIDE.md`

## Questions?

The system is designed to fail gracefully:
- Errors won't break your app
- Missing users get default values
- Offline actions queue automatically (Firestore)
- All operations are async and non-blocking

**Just add the helper calls and you're done!** 🚀
