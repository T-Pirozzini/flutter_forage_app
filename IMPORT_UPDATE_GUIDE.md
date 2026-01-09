# Import Update Guide

After running `cleanup_structure.bat`, you need to update imports across your codebase. Here's how to do it efficiently using VS Code's Find & Replace.

---

## Quick Method: VS Code Find & Replace

Press `Ctrl+Shift+H` (or `Cmd+Shift+H` on Mac) to open Find & Replace across all files.

### Step 1: Update Model Imports

**Find:** `import 'package:flutter_forager_app/models/`
**Replace:** `import 'package:flutter_forager_app/data/models/`
**Click:** Replace All

This will update:
- `comment.dart`
- `ingredient.dart`
- `marker.dart`
- `post.dart`
- `recipe.dart`
- `user.dart`

---

### Step 2: Update Ad Mob Service Import

**Find:** `import 'package:flutter_forager_app/components/ad_mob_service.dart';`
**Replace:** `import 'package:flutter_forager_app/data/services/ad_mob_service.dart';`
**Click:** Replace All

---

### Step 3: Update Location Service Import

**Find:** `import 'package:flutter_forager_app/services/location_service.dart';`
**Replace:** `import 'package:flutter_forager_app/data/services/location_service.dart';`
**Click:** Replace All

---

### Step 4: Update Friend Service Imports (Should be none now!)

**Find:** `import 'package:flutter_forager_app/services/friend_service.dart';`
**Expected:** 0 matches (we replaced these with UserRepository!)

If you find any, that means we missed updating a file - let me know!

---

### Step 5: Update Forage Services (Relative Imports)

These are trickier because they use relative imports in the forage screens.

#### Option A: Search and Replace Individually

In `lib/screens/forage/` folder files, find:

**Find:** `import '../services/map_service.dart';`
**Replace:** `import '../../data/services/map_service.dart';`

**Find:** `import '../services/marker_service.dart';`
**Replace:** `import '../../data/services/marker_service.dart';`

**Find:** `import '../services/map_permissions.dart';`
**Replace:** `import '../../data/services/map_permissions.dart';`

#### Option B: Use Absolute Imports (Better!)

**Find:** `import '../services/map_service.dart';`
**Replace:** `import 'package:flutter_forager_app/data/services/map_service.dart';`

**Find:** `import '../services/marker_service.dart';`
**Replace:** `import 'package:flutter_forager_app/data/services/marker_service.dart';`

**Find:** `import '../services/map_permissions.dart';`
**Replace:** `import 'package:flutter_forager_app/data/services/map_permissions.dart';`

---

## Verification Steps

After all replacements:

1. **Run:** `flutter pub get`

2. **Check for errors:**
   - Look at the Problems panel in VS Code
   - Should see 0 import errors

3. **Common issues:**
   - Red underlines on imports = path is wrong
   - "Target of URI doesn't exist" = file not found

4. **If you see errors:**
   - Double-check the file actually moved to the new location
   - Verify the import path matches the new location

---

## Expected Changes Summary

| Import Type | Old Path | New Path |
|-------------|----------|----------|
| Models | `lib/models/` | `lib/data/models/` |
| Ad Mob | `lib/components/ad_mob_service.dart` | `lib/data/services/ad_mob_service.dart` |
| Location | `lib/services/location_service.dart` | `lib/data/services/location_service.dart` |
| Map Service | `lib/screens/forage/services/map_service.dart` | `lib/data/services/map_service.dart` |
| Marker Service | `lib/screens/forage/services/marker_service.dart` | `lib/data/services/marker_service.dart` |
| Map Permissions | `lib/screens/forage/services/map_permissions.dart` | `lib/data/services/map_permissions.dart` |

---

## Files Most Likely to Need Updates

High-priority files that will definitely need import updates:

### Models (will update automatically with find/replace):
- Any file importing User, Marker, Post, Recipe, Comment, Ingredient

### Services:
- `lib/screens/community/community_page.dart` (if uses ad_mob_service)
- `lib/screens/forage/map_page.dart` (map services)
- `lib/screens/forage/marker_buttons.dart` (marker service)
- `lib/screens/forage/components/*.dart` (map services)
- Any page showing ads

---

## Quick Test

After updates, try to run:
```bash
flutter analyze
```

Should show 0 errors related to imports!

---

## Need Help?

If you run into import errors:
1. Share the error message
2. I'll help fix the specific paths
3. We can do it together file by file if needed

Ready to proceed!
