# Firestore Markers Migration Guide

## Overview

This guide walks you through migrating your Markers collection from user subcollections to a root collection.

**Current Structure:**
```
Users/{userEmail}/Markers/{markerId}
```

**New Structure:**
```
Markers/{markerId}
  - All existing fields
  - userId: {userEmail} (new field)
```

---

## Why This Migration is Necessary

The current subcollection structure prevents:
- ❌ Leaderboards (can't query "who has most markers?")
- ❌ Global marker search
- ❌ Efficient community features
- ❌ Gamification based on marker counts

The new root collection enables:
- ✅ Cross-user queries for leaderboards
- ✅ Efficient search and filtering
- ✅ Better performance
- ✅ Easier data analytics

---

## Pre-Migration Checklist

- [ ] **Backup your Firestore database** (Firebase Console → Firestore → Export)
- [ ] Read this entire guide first
- [ ] Test on a development/staging environment first (if possible)
- [ ] Ensure you have Firebase Admin SDK access
- [ ] Notify users of potential brief maintenance (optional, migration is non-breaking)

---

## Migration Steps

### Step 1: Dry Run (Test Mode)

First, run the migration in dry-run mode to see what will happen **without making any changes**:

```bash
# Navigate to project root
cd c:\Users\tpiro\Documents\programming\personal\flutter_forager_app

# Run dry run
dart scripts/migrate_markers.dart --dry-run
```

**Expected Output:**
```
================================================================================
FIRESTORE MARKER MIGRATION
================================================================================
Mode: DRY RUN (no changes will be made)

Step 1: Fetching all users...
✓ Found 305 users

Processing user: user1@example.com
  Found 15 markers
  [DRY RUN] Would migrate: marker_abc123
  [DRY RUN] Would migrate: marker_def456
  ...

================================================================================
MIGRATION SUMMARY
================================================================================
Total markers found:    2,847
Migrated successfully:  2,847
Skipped (already exist): 0
Errors:                 0

This was a DRY RUN. No changes were made.
Run again without --dry-run to perform actual migration.
```

### Step 2: Review Dry Run Results

Check the output for:
- Total markers found (should match your expectations)
- Any errors (investigate before proceeding)
- Verify the numbers make sense

### Step 3: Run Actual Migration

Once you're confident, run the real migration:

```bash
dart scripts/migrate_markers.dart
```

The script will:
1. Wait 10 seconds for you to cancel if needed
2. Fetch all users
3. For each user, copy their markers to the root `Markers` collection
4. Add `userId` and `migratedAt` fields to each marker
5. Keep original subcollections intact (as backup)

**Important:** The migration is **idempotent** - you can run it multiple times safely. Already-migrated markers will be skipped.

### Step 4: Verify Migration

1. **Check Firebase Console:**
   - Go to Firestore Database
   - Look for the new `Markers` root collection
   - Verify markers have `userId` and `migratedAt` fields
   - Spot-check a few markers to ensure data integrity

2. **Test Queries:**
   ```dart
   // Query all markers (now possible!)
   final allMarkers = await FirebaseFirestore.instance
       .collection('Markers')
       .limit(10)
       .get();

   // Query by user
   final userMarkers = await FirebaseFirestore.instance
       .collection('Markers')
       .where('userId', isEqualTo: 'user@example.com')
       .get();
   ```

### Step 5: Update App Code

Deploy the refactored app that uses:
- `MarkerRepository` instead of `MarkerService`
- Root `Markers` collection instead of subcollections

The refactored code is **backwards compatible** - it reads from the root collection but old app versions can still write to subcollections.

### Step 6: Monitor

After deploying:
- Monitor error logs for any migration-related issues
- Check that users can still:
  - Create markers
  - View their markers
  - View community markers
  - Bookmark markers

### Step 7: Cleanup (After 1-2 Weeks)

Once you've confirmed everything works:

```dart
// Optional cleanup script to remove old subcollections
// WARNING: Only run after confirming migration success!

// This can be done manually in Firebase Console:
// 1. Go to each user document
// 2. Delete the "Markers" subcollection
// 3. Or keep them as historical backup
```

---

## Troubleshooting

### "Failed to initialize Firebase"

**Problem:** Script can't connect to Firestore
**Solution:** Ensure you have `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) configured

### "Permission denied"

**Problem:** Insufficient Firestore permissions
**Solution:** Run script with admin credentials or update Firestore security rules temporarily

### Markers missing after migration

**Problem:** Migration didn't complete
**Solution:**
1. Check error logs from migration script
2. Re-run migration (it's safe to run multiple times)
3. Check if markers exist in old subcollections

### Duplicate markers

**Problem:** Markers appear twice
**Solution:** This shouldn't happen (script checks for existing markers), but if it does:
- The migration script skips existing markers
- Manually delete duplicates in Firebase Console

---

## Rollback Plan

If something goes wrong:

1. **Immediate rollback:**
   - Revert app to previous version
   - Old subcollections are still intact

2. **Clean up new collection:**
   ```dart
   // Delete the root Markers collection
   // WARNING: This deletes all migrated data!
   final markers = await FirebaseFirestore.instance
       .collection('Markers')
       .get();

   for (final doc in markers.docs) {
     await doc.reference.delete();
   }
   ```

3. **Re-run migration after fixing issues**

---

## Migration Checklist

- [ ] Exported Firestore backup
- [ ] Ran dry-run migration successfully
- [ ] Reviewed dry-run output
- [ ] Ran actual migration
- [ ] Verified markers in Firebase Console
- [ ] Tested marker queries
- [ ] Deployed refactored app
- [ ] Monitored for errors
- [ ] Confirmed all features work
- [ ] (Optional) Cleaned up old subcollections

---

## Firestore Security Rules Update

After migration, update your Firestore security rules to use the new structure:

```javascript
// OLD (subcollection)
match /Users/{userId}/Markers/{markerId} {
  allow read: if request.auth != null;
  allow create: if request.auth.uid == userId;
  allow update, delete: if request.auth.uid == userId;
}

// NEW (root collection)
match /Markers/{markerId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update, delete: if request.auth != null &&
                          resource.data.userId == request.auth.uid;
}
```

---

## Support

If you encounter issues:
1. Check error logs
2. Review this guide
3. Check the `REFACTOR_PLAN.md` for architecture details
4. Consult Firebase Firestore documentation

**Remember:** The migration is non-destructive. Original data remains in subcollections as backup.
