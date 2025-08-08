import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/models/marker.dart';
import 'package:flutter_forager_app/screens/forage/components/map_markers.dart';
import 'package:flutter_forager_app/screens/forage/components/map_style.dart';
import 'package:flutter_forager_app/screens/forage/services/map_permissions.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_forager_app/screens/forage/components/map_ui.dart';
import 'package:flutter_forager_app/screens/forage/components/map_view.dart';
import 'package:flutter_forager_app/providers/map/map_controller_provider.dart';
import 'package:flutter_forager_app/providers/map/map_state_provider.dart'
    hide mapControllerProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
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
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.locality ?? ''}${place.locality != null && place.country != null ? ', ' : ''}${place.country ?? ''}'
            .trim();
      }
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    } catch (e) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
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
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(_user.email)
                  .collection('Markers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final markers = snapshot.data?.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final location = data['location'] as Map<String, dynamic>;
                      return MarkerModel(
                        id: doc.id,
                        name: data['name'] ?? '',
                        description: data['description'] ?? '',
                        type: data['type'] ?? '',
                        imageUrls: List<String>.from(data['images'] ?? []),
                        markerOwner: data['markerOwner'] ?? '',
                        timestamp: (data['timestamp'] as Timestamp).toDate(),
                        latitude: (location['latitude'] as num).toDouble(),
                        longitude: (location['longitude'] as num).toDouble(),
                        status: data['status'] ?? 'active',
                        comments: (data['comments'] as List<dynamic>?)
                                ?.map((c) => MarkerComment.fromMap(c))
                                .toList() ??
                            [],
                        currentStatus: data['currentStatus'] ?? 'active',
                        statusHistory: (data['statusHistory'] as List<dynamic>?)
                                ?.map((s) => MarkerStatusUpdate.fromMap(s))
                                .toList() ??
                            [],
                      );
                    }).toList() ??
                    [];

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Locations',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          if (currentPosition != null)
                            ListTile(
                              leading: const Icon(Icons.my_location,
                                  color: Colors.blue),
                              title: const Text('Current Location'),
                              subtitle: FutureBuilder<String>(
                                future: _getLocationAddress(
                                    currentPosition.latitude,
                                    currentPosition.longitude),
                                builder: (context, snapshot) => Text(
                                  snapshot.data ?? 'Loading...',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey[600]),
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
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey[600]),
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
        return Colors.blue;
      case 'plant':
        return Colors.greenAccent;
      case 'other':
        return Colors.grey;
      default:
        return Colors.deepOrangeAccent;
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
                size: 32,
              ),
              const SizedBox(width: 8),
              Text('Add ${type[0].toUpperCase() + type.substring(1)} Marker'),
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
                  fillColor: Colors.grey[100],
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
                  fillColor: Colors.grey[100],
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
                  Icon(Icons.camera_alt_outlined,
                      color: Colors.deepOrangeAccent),
                  SizedBox(width: 8),
                  Flexible(
                    child: StyledTextSmall(
                        'Take photos of your find! Add them to your marker later.',
                        color: AppColors.textColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person, color: Colors.deepOrangeAccent),
                  StyledTitleMedium('Profile', color: AppColors.textColor),
                  Spacer(),
                  Icon(Icons.arrow_circle_right_outlined, color: Colors.white),
                  Spacer(),
                  Icon(Icons.location_on, color: Colors.deepOrangeAccent),
                  StyledTitleMedium('Locations', color: AppColors.textColor)
                ],
              ),
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
                backgroundColor: Colors.deepOrangeAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();
                  Navigator.of(context).pop();
                  try {
                    final position = await MapPermissions.getCurrentPosition();
                    final markerService =
                        MapMarkerService(FirebaseAuth.instance.currentUser!);
                    await markerService.saveMarker(
                      name: name,
                      description: description,
                      type: type,
                      images: [],
                      position: position,
                    );
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                          content: Text('Marker saved successfully')),
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
      appBar: AppBar(
        title: const StyledHeading('Forage Map'),
        toolbarHeight: 60,
      ),
      body: Column(
        children: [
          const MapHeader(),
          Expanded(
            child: Stack(
              children: [
                // Map View
                MapView(
                  markers: markers,
                  circles: circles,
                  initialCameraPosition: CameraPosition(
                    target: widget.initialLocation ??
                        LatLng(currentPosition.latitude,
                            currentPosition.longitude),
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
          ),
        ],
      ),
    );
  }
}
