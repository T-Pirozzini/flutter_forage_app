# Flutter Forager - Architecture Refactor Plan

## Overview
This document outlines the critical architecture fixes needed before implementing new features (onboarding, gamification, notifications).

**Timeline:** 2-3 weeks
**Goal:** Create scalable foundation for future features

---

## Critical Issues Being Fixed

### 1. Firestore Structure (BLOCKER)
**Current:** `Users/{email}/Markers/{id}` (subcollections)
**Problem:** Cannot query across all users for leaderboards/gamification
**Fix:** Move to `Markers/{id}` with `userId` field

### 2. No Repository Layer
**Current:** 79 direct Firestore calls in UI code
**Problem:** Cannot cache, test, or add offline support
**Fix:** Create repository layer to centralize all data access

### 3. Missing UserModel Fields
**Current:** No fields for gamification, notifications, or subscriptions
**Problem:** Can't add new features without breaking changes
**Fix:** Add all needed fields now

### 4. StateNotifier Disposal Bug
**Current:** Subscriptions never cancelled (memory leak)
**Fix:** Proper cleanup implementation

---

## New Folder Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── firestore_collections.dart    # Collection name constants
│   └── utils/
│       └── forage_type_utils.dart        # Shared type color/icon logic
├── data/
│   ├── models/                           # Move existing models here
│   │   ├── user.dart
│   │   ├── marker.dart
│   │   ├── post.dart
│   │   ├── recipe.dart
│   │   └── notification_preferences.dart  # NEW
│   ├── repositories/                     # NEW - Data access layer
│   │   ├── base_repository.dart
│   │   ├── marker_repository.dart
│   │   ├── user_repository.dart
│   │   ├── post_repository.dart
│   │   └── recipe_repository.dart
│   └── services/
│       └── firebase/
│           └── firestore_service.dart    # Firebase instance wrapper
├── features/                             # Future reorganization
├── providers/                            # Keep existing for now
├── screens/                              # Keep existing for now
└── ... (existing structure)
```

---

## Migration Tasks

### Phase 1: Foundation (Week 1)
- [x] Create new folder structure
- [ ] Create Firestore constants file
- [ ] Update UserModel with new fields
- [ ] Create NotificationPreferences model
- [ ] Create base Repository class
- [ ] Create FirestoreService wrapper

### Phase 2: Repositories (Week 1-2)
- [ ] Create MarkerRepository
- [ ] Create UserRepository
- [ ] Create migration script for Markers collection
- [ ] Test repositories with existing data

### Phase 3: Integration (Week 2)
- [ ] Update MapPage to use MarkerRepository
- [ ] Update CommunityPage to use repositories
- [ ] Update ForageLocationsPage to use MarkerRepository
- [ ] Fix MarkersNotifier disposal bug
- [ ] Remove old MarkerService

### Phase 4: Testing & Cleanup (Week 3)
- [ ] Test all critical flows
- [ ] Verify no regressions
- [ ] Update remaining screens
- [ ] Document new architecture

---

## Breaking Changes

### Data Migration Required
**Markers Collection:** Must run one-time migration script to move all user markers to root collection.

**Script location:** `scripts/migrate_markers.dart` (to be created)

### UserModel Changes
New fields added (backwards compatible):
- `points`, `level`, `achievements`
- `activityStats`, `streakData`
- `subscriptionTier`, `subscriptionExpiry`
- `notificationPreferences`

---

## Risk Mitigation

### Data Safety
1. **Backup Firestore** before running migration
2. Keep old Markers subcollections temporarily
3. Test migration on dev/staging first

### User Impact
- No downtime required
- Gradual rollout of repository changes
- Old app versions continue to work during migration

### Rollback Plan
- Keep old service layer until all screens updated
- Can revert repository changes without data loss
- Markers migration is reversible

---

## Post-Refactor Benefits

### For Features
✅ Leaderboards possible (query all markers)
✅ Gamification ready (points/achievements in UserModel)
✅ Notifications ready (preferences + device tokens)
✅ Premium features ready (subscription fields)

### For Development
✅ Testable code (repositories are mockable)
✅ Cacheable queries (centralized data access)
✅ Consistent patterns (all data through repositories)
✅ Easier debugging (single point of data access)

---

## Success Metrics

- [ ] All Firestore queries go through repositories
- [ ] No direct `FirebaseFirestore.instance` calls in UI
- [ ] Markers successfully migrated to root collection
- [ ] No memory leaks (StateNotifier properly disposed)
- [ ] All existing features work as before
- [ ] New fields in UserModel ready for gamification

---

## Next Steps After Refactor

Once this refactor is complete, we can proceed with:
1. Onboarding flow
2. Gamification system
3. Push notifications
4. Premium features

All of these will be much easier with proper architecture in place.
