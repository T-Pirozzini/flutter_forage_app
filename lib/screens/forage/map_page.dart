import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
import 'package:flutter_forager_app/screens/forage/components/map_markers.dart';
import 'package:flutter_forager_app/screens/forage/components/map_style.dart';
import 'package:flutter_forager_app/data/services/map_permissions.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
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
import 'package:intl/intl.dart';

class MapPage extends ConsumerStatefulWidget {
  final LatLng? initialLocation;
  const MapPage({this.initialLocation, super.key});

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

  void _showMarkerDetailsDialog(
      BuildContext parentContext, BuildContext context, String type) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    MarkerVisibility selectedVisibility = MarkerVisibility.private;

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
                  Text('Add ${type[0].toUpperCase() + type.substring(1)} Marker',
                      style: AppTheme.title(size: 14, weight: FontWeight.bold)),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                    // Visibility selector
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 8),
                            child: Text(
                              'Visibility',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          ...MarkerVisibility.values.map((visibility) {
                            return RadioListTile<MarkerVisibility>(
                              title: Text(
                                visibility.displayName,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                visibility.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              value: visibility,
                              groupValue: selectedVisibility,
                              dense: true,
                              activeColor: AppTheme.accent,
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedVisibility = value;
                                  });
                                }
                              },
                            );
                          }),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.camera_alt_outlined, color: AppTheme.accent),
                        SizedBox(width: 8),
                        Flexible(
                          child: StyledTextSmall(
                              'Take photos of your find! Add them to your marker later.',
                              color: AppTheme.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, color: AppTheme.accent),
                            SizedBox(width: 8),
                            StyledTitleMedium('Profile', color: AppTheme.textDark),
                            SizedBox(width: 20),
                            Icon(Icons.arrow_circle_right_outlined,
                                color: Colors.white),
                            SizedBox(width: 20),
                            Icon(Icons.location_on, color: AppTheme.accent),
                            SizedBox(width: 8),
                            StyledTitleMedium('Locations', color: AppTheme.textDark)
                          ],
                        ),
                      ),
                    )
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
                          images: [],
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
            onFollowPressed: () {
              ref.read(followUserProvider.notifier).state = !followUser;
            },
            onAddMarkerPressed: (dialogContext, type) =>
                _showMarkerDetailsDialog(context, dialogContext, type),
            onPlaceSelected: _goToPlace,
            onShowLocationsPressed: _showLocationsBottomSheet,
            onZoomIn: () => _mapController.zoomIn(),
            onZoomOut: () => _mapController.zoomOut(),
          ),
        ],
      ),
    );
  }
}
