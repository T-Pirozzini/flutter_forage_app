import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
import 'package:flutter_forager_app/screens/forage/components/map_markers.dart';
import 'package:flutter_forager_app/screens/forage/components/map_style.dart';
import 'package:flutter_forager_app/data/services/map_permissions.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_forager_app/screens/forage/components/map_ui.dart';
import 'package:flutter_forager_app/screens/forage/components/map_view.dart';
import 'package:flutter_forager_app/screens/forage/components/marker_filter_chips.dart';
import 'package:flutter_forager_app/screens/forage/components/locations_bottom_sheet.dart';
import 'package:flutter_forager_app/providers/map/map_controller_provider.dart';
import 'package:flutter_forager_app/providers/map/map_state_provider.dart';
import 'package:flutter_forager_app/shared/gamification/gamification_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class MapPage extends ConsumerStatefulWidget {
  final LatLng? initialLocation;
  final bool isFullScreen;

  const MapPage({
    this.initialLocation,
    this.isFullScreen = false,
    super.key,
  });

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  late final MapController _mapController;
  bool _isLoading = true;
  final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _mapController = ref.read(mapControllerProvider);
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      await _mapController.initialize();
      if (widget.initialLocation != null) {
        await _mapController.moveToLocation(
          widget.initialLocation!,
          zoom: 16,
        );
        ref.read(followUserProvider.notifier).state = false;
      } else {
        ref.read(followUserProvider.notifier).state = true;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing map: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLocationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationsBottomSheet(
        onLocationSelected: (latLng, markerType) {
          // Ensure the marker's type is visible before navigating (case-insensitive)
          final currentVisible = ref.read(visibleMarkerTypesProvider);
          final currentVisibleLower = currentVisible.map((t) => t.toLowerCase()).toSet();
          final markerTypeLower = markerType.toLowerCase();
          if (!currentVisibleLower.contains(markerTypeLower)) {
            ref.read(visibleMarkerTypesProvider.notifier).state = {
              ...currentVisible,
              markerTypeLower, // Add lowercase version to match filter
            };
          }
          _mapController.moveToLocation(latLng, zoom: 16);
          ref.read(followUserProvider.notifier).state = false;
        },
      ),
    );
  }

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
        return AppTheme.primary;
      case 'plant':
        return Colors.greenAccent;
      case 'other':
        return Colors.grey;
      default:
        return AppTheme.accent;
    }
  }

  /// Build visibility option tiles with icons and point bonuses
  List<Widget> _buildVisibilityOptions({
    required MarkerVisibility selectedVisibility,
    required void Function(MarkerVisibility) onChanged,
  }) {
    final options = [
      _VisibilityOption(
        visibility: MarkerVisibility.private,
        icon: Icons.lock_outline,
        iconColor: Colors.grey,
        bonus: null,
      ),
      _VisibilityOption(
        visibility: MarkerVisibility.closeFriends,
        icon: Icons.star_outline,
        iconColor: Colors.amber,
        bonus: null,
      ),
      _VisibilityOption(
        visibility: MarkerVisibility.friends,
        icon: Icons.people_outline,
        iconColor: AppTheme.primary,
        bonus: '+15 pts',
      ),
      _VisibilityOption(
        visibility: MarkerVisibility.specific,
        icon: Icons.person_outline,
        iconColor: Colors.blue,
        bonus: null,
      ),
      _VisibilityOption(
        visibility: MarkerVisibility.public,
        icon: Icons.public,
        iconColor: AppTheme.accent,
        bonus: '+15 pts',
      ),
    ];

    return options.map((option) {
      final isSelected = selectedVisibility == option.visibility;
      return InkWell(
        onTap: () => onChanged(option.visibility),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accent.withValues(alpha: 0.1) : null,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: option.visibility == MarkerVisibility.public ? 0 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: option.iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  option.icon,
                  size: 18,
                  color: option.iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.visibility.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppTheme.accent : Colors.black87,
                      ),
                    ),
                    Text(
                      option.visibility.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (option.bonus != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    option.bonus!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected ? AppTheme.accent : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showMarkerDetailsDialog(
      BuildContext parentContext, BuildContext context, String type) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    MarkerVisibility selectedVisibility = MarkerVisibility.private;
    List<File> selectedImages = [];
    final picker = ImagePicker();

    Future<void> pickImage(ImageSource source, StateSetter setDialogState) async {
      if (selectedImages.length >= 3) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(content: Text('Maximum of 3 photos allowed')),
        );
        return;
      }
      try {
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        if (pickedFile != null) {
          setDialogState(() {
            selectedImages.add(File(pickedFile.path));
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  ImageIcon(
                    AssetImage(
                        'lib/assets/images/${type.toLowerCase()}_marker.png'),
                    color: _getTypeColor(type),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('Add ${type[0].toUpperCase() + type.substring(1)} Marker',
                        style: AppTheme.title(size: 14, weight: FontWeight.bold)),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // Photo upload section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.camera_alt, color: AppTheme.accent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Add Photos (Optional)',
                                style: AppTheme.body(size: 14, weight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Photo picker buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => pickImage(ImageSource.camera, setDialogState),
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  label: const Text('Camera'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.accent,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => pickImage(ImageSource.gallery, setDialogState),
                                  icon: const Icon(Icons.photo_library, size: 18),
                                  label: const Text('Gallery'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.accent,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Photo preview thumbnails
                          if (selectedImages.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 70,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            selectedImages[index],
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () {
                                              setDialogState(() {
                                                selectedImages.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            selectedImages.isEmpty
                                ? 'No service? You can add photos later from the location detail screen.'
                                : '${selectedImages.length}/3 photos added',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: AppTheme.backgroundLight,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: AppTheme.backgroundLight,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Enhanced visibility selector
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                            child: Text(
                              'Who can see this location?',
                              style: AppTheme.body(size: 14, weight: FontWeight.w600),
                            ),
                          ),
                          ..._buildVisibilityOptions(
                            selectedVisibility: selectedVisibility,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedVisibility = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (selectedVisibility == MarkerVisibility.specific)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'You can select specific friends after creating the marker.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    nameController.dispose();
                    descriptionController.dispose();
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final name = nameController.text.trim();
                      final description = descriptionController.text.trim();

                      try {
                        final position = await MapPermissions.getCurrentPosition();

                        // Check GPS accuracy before saving
                        if (position.accuracy > 50) {
                          final proceed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Row(
                                children: [
                                  Icon(Icons.gps_off, color: AppTheme.warning),
                                  const SizedBox(width: 8),
                                  const Text('Low GPS Accuracy'),
                                ],
                              ),
                              content: Text(
                                'Current GPS accuracy: ${position.accuracy.toInt()}m\n\n'
                                'The marker location may be inaccurate. '
                                'For best results, wait for better GPS signal.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Wait'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accent,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Save Anyway'),
                                ),
                              ],
                            ),
                          );

                          if (proceed != true) return;
                        }

                        Navigator.of(context).pop();

                        final markerService =
                            MapMarkerService(FirebaseAuth.instance.currentUser!);
                        await markerService.saveMarker(
                          name: name,
                          description: description,
                          type: type,
                          images: selectedImages,
                          position: position,
                          visibility: selectedVisibility,
                        );

                        // Award points for creating marker
                        await GamificationHelper.awardMarkerCreated(
                          context: parentContext,
                          ref: ref,
                          userId: FirebaseAuth.instance.currentUser!.email!,
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(content: Text('Error saving marker: $e')),
                        );
                      } finally {
                        nameController.dispose();
                        descriptionController.dispose();
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _goToPlace(Map<String, dynamic> place) async {
    try {
      ref.read(followUserProvider.notifier).state = false;
      final geometry = place['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final double? lat = location?['lat'] as double?;
      final double? lng = location?['lng'] as double?;

      if (lat == null || lng == null) {
        throw Exception('Invalid place data: Missing latitude or longitude');
      }

      final latLng = LatLng(lat, lng);
      await _mapController.moveToLocation(latLng, zoom: 14);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error navigating to place: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = ref.watch(markersProvider);
    final circles = ref.watch(circlesProvider);
    final followUser = ref.watch(followUserProvider);
    final currentPosition = ref.watch(currentPositionProvider);

    if (_isLoading || currentPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final safePadding = MediaQuery.of(context).padding;

    // Determine if we should show the back button
    // Show it when opened standalone (with initialLocation) or explicitly in fullscreen mode
    final showBackButton = widget.initialLocation != null || widget.isFullScreen;

    return Scaffold(
      body: Stack(
        children: [
          // Map View
          MapView(
            markers: markers,
            circles: circles,
            initialCameraPosition: CameraPosition(
              target: widget.initialLocation ??
                  LatLng(currentPosition.latitude, currentPosition.longitude),
              zoom: 16,
            ),
            focusLocation: widget.initialLocation,
            onMapCreated: (controller) {
              _mapController.completeController(controller);
              controller.setMapStyle(mapstyle);
            },
          ),

          // Filter Chips - positioned above search field
          Positioned(
            top: safePadding.top + 8, // Above search field
            left: 0,
            right: 0,
            child: const MarkerFilterChips(),
          ),

          // Floating Controls Overlay
          MapFloatingControls(
            followUser: followUser,
            isFullScreen: showBackButton,
            onFollowPressed: () async {
              final newFollowState = !followUser;
              ref.read(followUserProvider.notifier).state = newFollowState;

              // Immediately center on user when toggling ON
              if (newFollowState) {
                // Set flag to prevent onCameraMoveStarted from disabling follow
                ref.read(isProgrammaticMoveProvider.notifier).state = true;
                await _mapController.moveToLocation(
                  LatLng(currentPosition.latitude, currentPosition.longitude),
                  zoom: 16,
                );
                // Reset flag after a short delay (camera animation takes time)
                Future.delayed(const Duration(milliseconds: 500), () {
                  ref.read(isProgrammaticMoveProvider.notifier).state = false;
                });
              }
            },
            onAddMarkerPressed: (dialogContext, type) =>
                _showMarkerDetailsDialog(context, dialogContext, type),
            onPlaceSelected: _goToPlace,
            onShowLocationsPressed: _showLocationsBottomSheet,
            onZoomIn: () => _mapController.zoomIn(),
            onZoomOut: () => _mapController.zoomOut(),
            onFullScreenPressed: showBackButton
                ? null // Already in full screen, no button needed
                : () {
                    // Open map in full screen mode
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MapPage(isFullScreen: true),
                      ),
                    );
                  },
          ),

          // Back button when in full screen mode
          if (showBackButton)
            Positioned(
              top: safePadding.top + 12,
              left: 12,
              child: FloatingActionButton(
                heroTag: 'backButton',
                mini: true,
                backgroundColor: AppTheme.primary,
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Helper class for visibility option data
class _VisibilityOption {
  final MarkerVisibility visibility;
  final IconData icon;
  final Color iconColor;
  final String? bonus;

  const _VisibilityOption({
    required this.visibility,
    required this.icon,
    required this.iconColor,
    this.bonus,
  });
}
