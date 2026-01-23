import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/forage/components/map_markers.dart';
import 'package:flutter_forager_app/screens/forage/components/map_style.dart';
import 'package:flutter_forager_app/data/services/map_permissions.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_forager_app/screens/forage/components/map_ui.dart';
import 'package:flutter_forager_app/screens/forage/components/map_view.dart';
import 'package:flutter_forager_app/providers/map/map_controller_provider.dart';
import 'package:flutter_forager_app/providers/map/map_state_provider.dart';
import 'package:flutter_forager_app/shared/gamification/gamification_helper.dart';
import 'package:flutter_forager_app/data/services/geocoding_cache.dart';
import 'package:intl/intl.dart';

class MapPage extends ConsumerStatefulWidget {
  final LatLng? initialLocation;
  const MapPage({this.initialLocation, super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  late final MapController _mapController;
  late final User _user;
  bool _isLoading = true;
  final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
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

  Future<String> _getLocationAddress(double lat, double lng) async {
    return GeocodingCache.getAddress(lat, lng);
  }

  void _showLocationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final currentPosition = ref.watch(currentPositionProvider);
            final markerRepo = ref.watch(markerRepositoryProvider);

            return StreamBuilder<List<MarkerModel>>(
              stream: markerRepo.streamByUserId(_user.email!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final markers = snapshot.data ?? [];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Text(
                        'Locations',
                        style: AppTheme.heading(size: 18),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          if (currentPosition != null)
                            ListTile(
                              leading: const Icon(Icons.my_location,
                                  color: AppTheme.primary),
                              title: const Text('Current Location'),
                              subtitle: FutureBuilder<String>(
                                future: _getLocationAddress(
                                    currentPosition.latitude,
                                    currentPosition.longitude),
                                builder: (context, snapshot) => Text(
                                  snapshot.data ?? 'Loading...',
                                  style: AppTheme.caption(
                                      size: 12, color: AppTheme.textMedium),
                                ),
                              ),
                              onTap: () {
                                _mapController.moveToLocation(
                                  LatLng(currentPosition.latitude,
                                      currentPosition.longitude),
                                  zoom: 16,
                                );
                                ref.read(followUserProvider.notifier).state =
                                    true;
                                Navigator.pop(context);
                              },
                            ),
                          ...markers.map((marker) {
                            return ListTile(
                              leading: ImageIcon(
                                AssetImage(
                                    'lib/assets/images/${marker.type.toLowerCase()}_marker.png'),
                                color: _getTypeColor(marker.type),
                              ),
                              title: Text(marker.name.isEmpty
                                  ? 'Unnamed'
                                  : marker.name),
                              subtitle: FutureBuilder<String>(
                                future: _getLocationAddress(
                                    marker.latitude, marker.longitude),
                                builder: (context, snapshot) => Text(
                                  snapshot.data ?? 'Loading...',
                                  style: AppTheme.caption(
                                      size: 12, color: AppTheme.textMedium),
                                ),
                              ),
                              onTap: () {
                                _mapController.moveToLocation(
                                  LatLng(marker.latitude, marker.longitude),
                                  zoom: 16,
                                );
                                ref.read(followUserProvider.notifier).state =
                                    false;
                                Navigator.pop(context);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
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

    showDialog(
      context: context,
      builder: (context) {
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
          ),
        ],
      ),
    );
  }
}
