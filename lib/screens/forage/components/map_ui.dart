import 'package:flutter/material.dart';
import 'package:flutter_forager_app/providers/map/map_state_provider.dart';
import 'package:flutter_forager_app/screens/forage/components/search_field.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
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

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'berries':
      case 'berry':
        return Colors.purpleAccent;
      case 'mushrooms':
      case 'mushroom':
        return Colors.orangeAccent;
      case 'nuts':
        return Colors.brown;
      case 'herbs':
        return Colors.lightGreen;
      case 'tree':
        return Colors.green;
      case 'fish':
        return Colors.blue;
      case 'plant':
        return Colors.greenAccent;
      case 'other':
        return Colors.grey;
      default:
        return Colors.deepOrangeAccent;
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
                // View Locations Button
                Tooltip(
                  message: 'View your locations',
                  child: FloatingActionButton(
                    heroTag: 'locationsButton',
                    onPressed: onShowLocationsPressed,
                    mini: true,
                    backgroundColor: Colors.grey.shade800,
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
                    backgroundColor: Colors.grey.shade800,
                    child: Icon(
                      Icons.my_location,
                      color: followUser
                          ? Colors.deepOrange.shade300
                          : Colors.white,
                    ),
                  ),
                ),
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
                color: Colors.black87,
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
                    backgroundColor: Colors.deepOrange.shade300,
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

class MapHeader extends StatelessWidget {
  const MapHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false, // Only apply safe area to top
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.primaryAccent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: StyledTextLarge(
                "Explore your local area for forageable ingredients.",
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: StyledTextLarge(
                'Mark the location so you can find it again!',
                color: AppColors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
