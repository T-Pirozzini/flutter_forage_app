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

    return Stack(
      children: [
        Positioned(
          top: 250,
          left: 20,
          right: 20,
          child: SearchField(
            onPlaceSelected: onPlaceSelected,
          ),
        ),
        Positioned(
          bottom: 150.0,
          right: 0.0,
          child: Tooltip(
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
              shape: const RoundedRectangleBorder(),
              mini: true,
              backgroundColor: Colors.grey.shade800,
              child: Icon(
                Icons.my_location,
                color: followUser ? Colors.deepOrange.shade300 : Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          top: 350.0,
          right: 0.0,
          child: Tooltip(
            message: 'View your locations',
            child: FloatingActionButton(
              heroTag: 'locationsButton',
              onPressed: onShowLocationsPressed,
              shape: const RoundedRectangleBorder(),
              mini: true,
              backgroundColor: Colors.grey.shade800,
              child: const Icon(
                Icons.list,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 50.0,
          left: 25.0, // Aligned with other FABs
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
            color: Colors.black87,
            child: Column(
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
                  shape: const RoundedRectangleBorder(),
                  tooltip: 'Add a new marker',
                  children: markerTypes.map((type) {
                    return SpeedDialChild(
                      child: ImageIcon(
                        AssetImage(
                            'lib/assets/images/${type.toLowerCase()}_marker.png'),
                        color: _getTypeColor(type),
                        size: 24,
                      ),
                      // label: type[0].toUpperCase() + type.substring(1),
                      // labelStyle:
                      // const TextStyle(color: Colors.black87, fontSize: 12),
                      backgroundColor: Colors.white,
                      onTap: () => onAddMarkerPressed(context, type),
                    );
                  }).toList(),
                  animationDuration: const Duration(milliseconds: 200),
                  overlayColor: Colors.black,
                  overlayOpacity: 0.2,
                ),
                const SizedBox(height: 10), // Spacing between buttons
                Text(
                  'Add a Marker',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MapHeader extends StatelessWidget {
  const MapHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      color: AppColors.primaryAccent,
      child: Column(
        children: [
          StyledTextLarge("Explore your local area for forageable ingredients.",
              color: AppColors.textColor),
          StyledTextLarge('Mark the location so you can find it again!',
              color: AppColors.textColor),
        ],
      ),
    );
  }
}
