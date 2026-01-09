@echo off
echo ========================================
echo Flutter Forager - File Structure Cleanup
echo ========================================
echo.

REM Phase 1: Critical Cleanup
echo [PHASE 1] Critical Cleanup...
echo.

echo [1/3] Consolidating models to data/models/...
if exist "lib\models\comment.dart" move "lib\models\comment.dart" "lib\data\models\comment.dart"
if exist "lib\models\ingredient.dart" move "lib\models\ingredient.dart" "lib\data\models\ingredient.dart"
if exist "lib\models\marker.dart" move "lib\models\marker.dart" "lib\data\models\marker.dart"
if exist "lib\models\post.dart" move "lib\models\post.dart" "lib\data\models\post.dart"
if exist "lib\models\recipe.dart" move "lib\models\recipe.dart" "lib\data\models\recipe.dart"
if exist "lib\models\user.dart" move "lib\models\user.dart" "lib\data\models\user.dart"
if exist "lib\models\" rmdir "lib\models"
echo   ✓ Models consolidated

echo.
echo [2/3] Removing legacy service...
if exist "lib\services\friend_service.dart" del "lib\services\friend_service.dart"
echo   ✓ Removed friend_service.dart

echo.
echo [3/3] Organizing services to data/services/...
if exist "lib\components\ad_mob_service.dart" move "lib\components\ad_mob_service.dart" "lib\data\services\ad_mob_service.dart"
if exist "lib\services\location_service.dart" move "lib\services\location_service.dart" "lib\data\services\location_service.dart"

REM Create data/services directory if it doesn't exist for the screen services
if not exist "lib\data\services" mkdir "lib\data\services"

if exist "lib\screens\forage\services\map_service.dart" move "lib\screens\forage\services\map_service.dart" "lib\data\services\map_service.dart"
if exist "lib\screens\forage\services\marker_service.dart" move "lib\screens\forage\services\marker_service.dart" "lib\data\services\marker_service.dart"
if exist "lib\screens\forage\services\map_permissions.dart" move "lib\screens\forage\services\map_permissions.dart" "lib\data\services\map_permissions.dart"

REM Clean up empty directories
if exist "lib\screens\forage\services\" rmdir "lib\screens\forage\services"
if exist "lib\services\" rmdir "lib\services"
echo   ✓ Services organized

echo.
echo ========================================
echo Phase 1 Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Update imports (I'll help you with find/replace)
echo 2. Run: flutter pub get
echo 3. Check for any import errors in your IDE
echo.
pause
