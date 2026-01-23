import 'package:flutter/material.dart';
import 'package:flutter_forager_app/providers/map/map_state_provider.dart';
import 'package:flutter_forager_app/screens/forage/components/search_field.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class MapFloatingControls extends ConsumerWidget {
  final bool followUser;
  final VoidCallback onFollowPressed;
  final void Function(BuildContext, String) onAddMarkerPressed;
  final Function(Map<String, dynamic>) onPlaceSelected;
  final VoidCallback onShowLocationsPressed;

  const MapFloatingControls({
    super.key,
    required this.followUser,
    required this.onFollowPressed,
    required this.onAddMarkerPressed,
    required this.onPlaceSelected,
    required this.onShowLocationsPressed,
  });

  void _showExploreInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        title: Row(
          children: [
            Icon(Icons.explore, color: AppTheme.secondary),
            const SizedBox(width: 8),
            Text(
              'Explore & Forage',
              style: AppTheme.heading(size: 18, color: AppTheme.textDark),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore your local area for forageable ingredients.',
              style: AppTheme.body(size: 14, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              'Mark the location so you can find it again!',
              style: AppTheme.body(size: 14, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.add_circle_outline, color: AppTheme.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap the + button to add a new marker',
                    style: AppTheme.caption(size: 12, color: AppTheme.textMedium),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.my_location, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap to center map on your location',
                    style: AppTheme.caption(size: 12, color: AppTheme.textMedium),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: AppTheme.button(color: AppTheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    // Using AppTheme colors for consistency
    switch (type.toLowerCase()) {
      case 'berries':
      case 'berry':
        return const Color(0xFF9C27B0); // Purple
      case 'mushrooms':
      case 'mushroom':
        return AppTheme.secondary; // Warm amber
      case 'nuts':
        return const Color(0xFF795548); // Brown
      case 'herbs':
        return const Color(0xFF8BC34A); // Light green
      case 'tree':
        return AppTheme.primary; // Forest green
      case 'fish':
        return const Color(0xFF2196F3); // Blue
      case 'plant':
        return AppTheme.success; // Success green
      case 'shellfish':
        return const Color(0xFFE91E63); // Pink
      case 'other':
        return AppTheme.textMedium; // Grey
      default:
        return AppTheme.accent; // Coral
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markerTypes = [
      'plant',
      'tree',
      'mushroom',
      'berries',
      'fish',
      'nuts',
      'shellfish'
    ];

    final screenSize = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    return SafeArea(
      child: Stack(
        children: [
          // Search Field - Top Center
          Positioned(
            top: safePadding.top + 20, // 20px below safe area
            left: 20,
            right: 20,
            child: SearchField(
              onPlaceSelected: onPlaceSelected,
            ),
          ),

          // Right Side Controls Column
          Positioned(
            right: 16,
            top: screenSize.height * 0.3, // Start at 30% of screen height
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info Button
                Tooltip(
                  message: 'About exploring',
                  child: FloatingActionButton(
                    heroTag: 'infoButton',
                    onPressed: () => _showExploreInfoDialog(context),
                    mini: true,
                    backgroundColor: AppTheme.secondary,
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // View Locations Button
                Tooltip(
                  message: 'View your locations',
                  child: FloatingActionButton(
                    heroTag: 'locationsButton',
                    onPressed: onShowLocationsPressed,
                    mini: true,
                    backgroundColor: AppTheme.primary,
                    child: const Icon(
                      Icons.list,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Follow Location Button
                Tooltip(
                  message: followUser
                      ? 'Following your location (2s delay after manual move)'
                      : 'Tap to follow your location',
                  child: FloatingActionButton(
                    heroTag: 'locationButton',
                    onPressed: () {
                      onFollowPressed();
                      if (followUser) {
                        ref.read(lastManualMoveProvider.notifier).state = null;
                      }
                    },
                    mini: true,
                    backgroundColor: AppTheme.primary,
                    child: Icon(
                      Icons.my_location,
                      color: followUser
                          ? AppTheme.accent
                          : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // GPS Accuracy Indicator
                _GpsAccuracyBadge(),
              ],
            ),
          ),

          // Add Marker SpeedDial - Bottom Left
          Positioned(
            bottom: safePadding.bottom - 20,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpeedDial(
                    icon: Icons.add,
                    activeIcon: Icons.close,
                    activeLabel: const Text(
                      'Close',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    buttonSize: const Size(56, 56), // Standard FAB size
                    childrenButtonSize: const Size(40, 40),
                    tooltip: 'Add a new marker',
                    children: markerTypes.map((type) {
                      return SpeedDialChild(
                        child: ImageIcon(
                          AssetImage(
                              'lib/assets/images/${type.toLowerCase()}_marker.png'),
                          color: _getTypeColor(type),
                          size: 18,
                        ),
                        backgroundColor: Colors.white,
                        onTap: () => onAddMarkerPressed(context, type),
                      );
                    }).toList(),
                    animationDuration: const Duration(milliseconds: 200),
                    overlayColor: Colors.black,
                    overlayOpacity: 0.2,
                    direction: SpeedDialDirection.up, // Opens upward
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add Marker',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small badge showing current GPS accuracy with color coding
class _GpsAccuracyBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(currentPositionProvider);

    if (position == null) {
      return const SizedBox.shrink();
    }

    final accuracy = position.accuracy;
    final color = _getAccuracyColor(accuracy);
    final icon = _getAccuracyIcon(accuracy);

    return Tooltip(
      message: 'GPS accuracy: ${accuracy.toInt()}m',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              '${accuracy.toInt()}m',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy <= 20) {
      return AppTheme.success; // Green - excellent
    } else if (accuracy <= 50) {
      return AppTheme.warning; // Amber - acceptable
    } else {
      return AppTheme.error; // Red - poor
    }
  }

  IconData _getAccuracyIcon(double accuracy) {
    if (accuracy <= 20) {
      return Icons.gps_fixed; // Strong signal
    } else if (accuracy <= 50) {
      return Icons.gps_not_fixed; // Moderate signal
    } else {
      return Icons.gps_off; // Weak signal
    }
  }
}
