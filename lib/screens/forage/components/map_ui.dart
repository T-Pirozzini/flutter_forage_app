import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/custom_marker_type.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/providers/map/map_state_provider.dart';
import 'package:flutter_forager_app/screens/forage/components/custom_marker_type_dialog.dart';
import 'package:flutter_forager_app/screens/forage/components/search_field.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapFloatingControls extends ConsumerWidget {
  final bool followUser;
  final bool isFullScreen;
  final VoidCallback onFollowPressed;
  final void Function(BuildContext, String) onAddMarkerPressed;
  final Function(Map<String, dynamic>) onPlaceSelected;
  final VoidCallback onShowLocationsPressed;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback? onFullScreenPressed;

  const MapFloatingControls({
    super.key,
    required this.followUser,
    this.isFullScreen = false,
    required this.onFollowPressed,
    required this.onAddMarkerPressed,
    required this.onPlaceSelected,
    required this.onShowLocationsPressed,
    required this.onZoomIn,
    required this.onZoomOut,
    this.onFullScreenPressed,
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
              'Map Controls',
              style: AppTheme.heading(size: 18, color: AppTheme.textDark),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore your area and mark forageable spots!',
                style: AppTheme.body(size: 14, color: AppTheme.textDark),
              ),
              const SizedBox(height: 16),
              // Add Marker
              _buildInfoRow(
                Icons.add_circle_outline,
                AppTheme.accent,
                'Add Marker',
                'Tap the + button to save a foraging spot at your current location',
              ),
              const SizedBox(height: 12),
              // My Location
              _buildInfoRow(
                Icons.my_location,
                AppTheme.primary,
                'My Location',
                'Centers the map on your current GPS location and follows you',
              ),
              const SizedBox(height: 12),
              // Map Type
              _buildInfoRow(
                Icons.terrain,
                AppTheme.primary,
                'Map Type',
                'Switch between terrain, satellite, and hybrid views',
              ),
              const SizedBox(height: 12),
              // Zoom
              _buildInfoRow(
                Icons.zoom_in,
                AppTheme.primary,
                'Zoom Controls',
                'Use + and - buttons to zoom in and out of the map',
              ),
              const SizedBox(height: 12),
              // Filter
              _buildInfoRow(
                Icons.filter_list_rounded,
                AppTheme.primary,
                'Filter Bar',
                'Tap marker types to show/hide them on the map',
              ),
              const SizedBox(height: 12),
              // Search
              _buildInfoRow(
                Icons.search_rounded,
                AppTheme.primary,
                'Search',
                'Search for any location to navigate there quickly',
              ),
              const SizedBox(height: 12),
              // My Locations Bar
              _buildInfoRow(
                Icons.expand_less_rounded,
                AppTheme.primary,
                'My Locations',
                'Tap the green bar to see a list of all your saved markers with distances',
              ),
              const SizedBox(height: 12),
              // Test Location
              _buildInfoRowWithBold(
                Icons.location_searching,
                AppTheme.warning,
                'Test Location',
                'Drag the target icon',
                ' onto the map to see distances from that point instead of your GPS',
              ),
              const SizedBox(height: 12),
              // GPS Accuracy
              _buildInfoRow(
                Icons.gps_fixed,
                AppTheme.success,
                'GPS Accuracy',
                'Shows how accurate your current GPS signal is (green = good, red = poor)',
              ),
            ],
          ),
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

  Widget _buildInfoRow(IconData icon, Color color, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.body(size: 13, color: AppTheme.textDark, weight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTheme.caption(size: 11, color: AppTheme.textMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowWithBold(IconData icon, Color color, String title, String boldPart, String normalPart) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.body(size: 13, color: AppTheme.textDark, weight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: boldPart,
                      style: AppTheme.caption(size: 11, color: AppTheme.textDark, weight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: normalPart,
                      style: AppTheme.caption(size: 11, color: AppTheme.textMedium),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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

    final safePadding = MediaQuery.of(context).padding;
    // Position just above the BottomNavigationBar
    // Nav bar is ~56px tall and sits above the safe area bottom padding
    final navBarHeight = 56.0 + safePadding.bottom - 48;

    // Check if search is focused to hide controls
    final isSearchFocused = ref.watch(isSearchFocusedProvider);

    return Stack(
      children: [
        // Search Field - Below filter chips
        Positioned(
          top: safePadding.top + 72, // Below filter chips
          left: 16,
          right: 16,
          child: SearchField(
            onPlaceSelected: onPlaceSelected,
            onFocusChanged: (isFocused) {
              ref.read(isSearchFocusedProvider.notifier).state = isFocused;
            },
          ),
        ),

        // Tap-to-dismiss overlay - covers map area outside search field when focused
        // Tapping anywhere on the map dismisses the keyboard and shows controls again
        if (isSearchFocused)
          Positioned(
            top: safePadding.top + 130, // Just below the search field (72 + ~58 for field height)
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

        // Right Side Controls Column - hide when search is focused
        if (!isSearchFocused)
          Positioned(
            right: 12,
            top: safePadding.top + 140, // Below search bar
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Compass Widget
                _CompassWidget(),
                const SizedBox(height: 10),
                // Map Type Toggle Button
                _MapTypeToggleButton(),
                const SizedBox(height: 10),
                // Follow Location Button
                Tooltip(
                  message: followUser
                      ? 'Following your location'
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
                      color: followUser ? AppTheme.accent : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // GPS Accuracy Indicator
                _GpsAccuracyBadge(),
                const SizedBox(height: 10),
                // Zoom Controls
                _ZoomControls(
                  onZoomIn: onZoomIn,
                  onZoomOut: onZoomOut,
                ),
                const SizedBox(height: 10),
                // Draggable test location target
                _DraggableSpoofTarget(),
              ],
            ),
          ),

        // Left Side Controls - Info and Fullscreen - hide when search is focused
        if (!isSearchFocused)
          Positioned(
            left: 12,
            top: safePadding.top + 140, // Below search bar, same as right side
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
                      size: 20,
                    ),
                  ),
                ),
                // Fullscreen Button - only show when not already in fullscreen
                if (onFullScreenPressed != null) ...[
                  const SizedBox(height: 10),
                  Tooltip(
                    message: 'Full screen mode',
                    child: FloatingActionButton(
                      heroTag: 'fullscreenButton',
                      onPressed: onFullScreenPressed,
                      mini: true,
                      backgroundColor: AppTheme.primary,
                      child: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Add Marker SpeedDial - Bottom Left corner - hide when search is focused
        if (!isSearchFocused)
          Positioned(
            bottom: navBarHeight + 44, // Above the locations bar
            left: 12,
            child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AddMarkerSpeedDial(
                  markerTypes: markerTypes,
                  getTypeColor: _getTypeColor,
                  onAddMarkerPressed: onAddMarkerPressed,
                ),
                const SizedBox(height: 4),
                Text(
                  'Add Marker',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Full-width Locations Bar - hide when search is focused
        if (!isSearchFocused)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
            onTap: onShowLocationsPressed,
            child: Container(
              // Height extends from tap area down through nav bar area (or safe area in fullscreen)
              height: isFullScreen ? safePadding.bottom + 36 : navBarHeight + 36,
              padding: EdgeInsets.only(bottom: isFullScreen ? safePadding.bottom : navBarHeight),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.expand_less_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'My Locations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.expand_less_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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

/// Draggable target for setting test/spoof location
/// When not active: shows a draggable target icon
/// When active: tapping clears it and returns to GPS following
class _DraggableSpoofTarget extends ConsumerWidget {
  const _DraggableSpoofTarget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isSpoofLocationActiveProvider);

    return Tooltip(
      message: isActive
          ? 'Tap to clear test location and follow GPS'
          : 'Drag onto map to set test location',
      child: GestureDetector(
        onTap: isActive
            ? () {
                // Clear spoof location and re-enable following
                ref.read(spoofLocationProvider.notifier).state = null;
                ref.read(followUserProvider.notifier).state = true;
              }
            : null,
        child: Draggable<String>(
          data: 'spoof_location',
          feedback: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warning.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_searching,
              color: Colors.white,
              size: 24,
            ),
          ),
          childWhenDragging: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.textMedium.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_searching,
              color: AppTheme.textMedium.withValues(alpha: 0.5),
              size: 18,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.warning : AppTheme.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? AppTheme.warning
                    : AppTheme.warning.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isActive ? AppTheme.warning : Colors.black)
                      .withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isActive ? Icons.close : Icons.location_searching,
              color: isActive ? Colors.white : AppTheme.warning,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggle button for switching between map types (terrain, satellite, hybrid)
class _MapTypeToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapType = ref.watch(mapTypeProvider);

    return Tooltip(
      message: _getTooltipMessage(mapType),
      child: FloatingActionButton(
        heroTag: 'mapTypeButton',
        onPressed: () {
          final types = [MapType.terrain, MapType.satellite, MapType.hybrid];
          final currentIndex = types.indexOf(mapType);
          final nextIndex = (currentIndex + 1) % types.length;
          ref.read(mapTypeProvider.notifier).state = types[nextIndex];
        },
        mini: true,
        backgroundColor: AppTheme.primary,
        child: Icon(
          _getMapTypeIcon(mapType),
          color: Colors.white,
        ),
      ),
    );
  }

  IconData _getMapTypeIcon(MapType type) {
    switch (type) {
      case MapType.terrain:
        return Icons.terrain;
      case MapType.satellite:
        return Icons.satellite_alt;
      case MapType.hybrid:
        return Icons.layers;
      default:
        return Icons.map;
    }
  }

  String _getTooltipMessage(MapType type) {
    switch (type) {
      case MapType.terrain:
        return 'Terrain view (tap for satellite)';
      case MapType.satellite:
        return 'Satellite view (tap for hybrid)';
      case MapType.hybrid:
        return 'Hybrid view (tap for terrain)';
      default:
        return 'Change map type';
    }
  }
}

/// Zoom in/out controls
class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom In
          _ZoomButton(
            icon: Icons.add,
            onPressed: onZoomIn,
            tooltip: 'Zoom in',
            isTop: true,
          ),
          Container(
            height: 1,
            width: 32,
            color: AppTheme.backgroundLight,
          ),
          // Zoom Out
          _ZoomButton(
            icon: Icons.remove,
            onPressed: onZoomOut,
            tooltip: 'Zoom out',
            isTop: false,
          ),
        ],
      ),
    );
  }
}

/// Individual zoom button
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isTop;

  const _ZoomButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.vertical(
            top: isTop ? const Radius.circular(8) : Radius.zero,
            bottom: isTop ? Radius.zero : const Radius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: 20,
              color: AppTheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// SpeedDial for adding markers with both built-in and custom types
class _AddMarkerSpeedDial extends ConsumerWidget {
  final List<String> markerTypes;
  final Color Function(String) getTypeColor;
  final void Function(BuildContext, String) onAddMarkerPressed;

  const _AddMarkerSpeedDial({
    required this.markerTypes,
    required this.getTypeColor,
    required this.onAddMarkerPressed,
  });

  /// Show options for custom marker type: Add Marker or Delete
  void _showCustomTypeOptions(
    BuildContext context,
    WidgetRef ref,
    CustomMarkerType customType,
    void Function(BuildContext, String) onAddMarker,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with emoji and name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(customType.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Text(
                      customType.name,
                      style: AppTheme.heading(size: 18, color: AppTheme.textDark),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Add Marker option
              ListTile(
                leading: Icon(Icons.add_location_alt, color: AppTheme.primary),
                title: Text('Add Marker', style: AppTheme.body(color: AppTheme.textDark)),
                subtitle: Text('Create a new marker of this type',
                  style: AppTheme.caption(color: AppTheme.textMedium)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onAddMarker(context, customType.typeId);
                },
              ),
              // Delete option
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppTheme.error),
                title: Text('Delete Type', style: AppTheme.body(color: AppTheme.error)),
                subtitle: Text('Remove this custom marker type',
                  style: AppTheme.caption(color: AppTheme.textMedium)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteType(context, ref, customType);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show confirmation dialog before deleting
  void _confirmDeleteType(BuildContext context, WidgetRef ref, CustomMarkerType customType) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(customType.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete "${customType.name}"?',
                style: AppTheme.heading(size: 16, color: AppTheme.textDark),
              ),
            ),
          ],
        ),
        content: Text(
          'This will remove the custom marker type. Existing markers of this type will not be deleted.',
          style: AppTheme.body(size: 14, color: AppTheme.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final repo = ref.read(customMarkerTypeRepositoryProvider);
                await repo.deleteType(customType.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted ${customType.emoji} ${customType.name}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting type: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customTypesAsync = ref.watch(customMarkerTypesProvider);

    // Build children list: built-in types + custom types + "Create Custom" option
    final List<SpeedDialChild> children = [];

    // Add built-in marker types
    for (final type in markerTypes) {
      children.add(SpeedDialChild(
        child: ImageIcon(
          AssetImage('lib/assets/images/${type.toLowerCase()}_marker.png'),
          color: getTypeColor(type),
          size: 20,
        ),
        backgroundColor: AppTheme.surfaceLight,
        labelBackgroundColor: AppTheme.surfaceLight,
        label: type[0].toUpperCase() + type.substring(1),
        labelStyle: TextStyle(
          color: AppTheme.textDark,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        onTap: () => onAddMarkerPressed(context, type),
      ));
    }

    // Add custom types if loaded (with delete option)
    customTypesAsync.whenData((customTypes) {
      for (final customType in customTypes) {
        children.add(SpeedDialChild(
          child: Text(
            customType.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          backgroundColor: AppTheme.surfaceLight,
          labelBackgroundColor: AppTheme.surfaceLight,
          label: customType.name,
          labelStyle: TextStyle(
            color: AppTheme.textDark,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          onTap: () => _showCustomTypeOptions(context, ref, customType, onAddMarkerPressed),
        ));
      }
    });

    // Add "Create Custom" option at the end
    children.add(SpeedDialChild(
      child: Icon(
        Icons.add_circle_outline,
        color: AppTheme.accent,
        size: 20,
      ),
      backgroundColor: AppTheme.surfaceLight,
      labelBackgroundColor: AppTheme.surfaceLight,
      label: 'Create Custom',
      labelStyle: TextStyle(
        color: AppTheme.accent,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      onTap: () => showCustomMarkerTypeDialog(
        context,
        onTypeCreated: (name, emoji) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created custom type: $emoji $name'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    ));

    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: AppTheme.accent,
      activeBackgroundColor: AppTheme.textMedium,
      foregroundColor: Colors.white,
      buttonSize: const Size(56, 56),
      childrenButtonSize: const Size(44, 44),
      tooltip: 'Add a new marker',
      children: children,
      animationDuration: const Duration(milliseconds: 200),
      overlayColor: AppTheme.backgroundDark,
      overlayOpacity: 0.3,
      direction: SpeedDialDirection.up,
      switchLabelPosition: true, // Labels on right side of icons
    );
  }
}

/// Compass widget showing current map bearing
/// Tap to reset map to north
class _CompassWidget extends ConsumerWidget {
  const _CompassWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bearing = ref.watch(mapBearingProvider);

    return Tooltip(
      message: bearing.abs() < 1 ? 'Facing North' : 'Tap to face North',
      child: GestureDetector(
        onTap: () async {
          // Reset bearing to north
          final completer = ref.read(mapCompleterProvider);
          if (completer.isCompleted) {
            final controller = await completer.future;
            final currentPosition = await controller.getVisibleRegion();
            final center = LatLng(
              (currentPosition.northeast.latitude + currentPosition.southwest.latitude) / 2,
              (currentPosition.northeast.longitude + currentPosition.southwest.longitude) / 2,
            );

            // Set flag to prevent disabling follow
            ref.read(isProgrammaticMoveProvider.notifier).state = true;
            await controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: center,
                  zoom: await controller.getZoomLevel(),
                  bearing: 0, // North
                ),
              ),
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              ref.read(isProgrammaticMoveProvider.notifier).state = false;
            });
          }
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating compass
              Transform.rotate(
                angle: -bearing * (3.14159265359 / 180), // Convert degrees to radians
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // North indicator (red)
                    Container(
                      width: 3,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // South indicator (white/grey)
                    Container(
                      width: 3,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.textLight,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Center dot
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              // N label at top when facing north
              if (bearing.abs() < 10)
                Positioned(
                  top: 4,
                  child: Text(
                    'N',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
