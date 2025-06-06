import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/forage/components/map_markers.dart';
import 'package:flutter_forager_app/screens/forage/components/map_style.dart';
import 'package:flutter_forager_app/screens/forage/services/map_permissions.dart';
import 'package:flutter_forager_app/screens/forage/services/marker_service.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_forager_app/screens/forage/components/map_ui.dart';
import 'package:flutter_forager_app/screens/forage/components/map_view.dart';
import 'package:flutter_forager_app/providers/map/map_controller_provider.dart';
import 'package:flutter_forager_app/providers/map/map_state_provider.dart'
    hide mapControllerProvider;

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  late final MapController _mapController;
  late final User _user;
  bool _isLoading = true;

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
      ref.read(followUserProvider.notifier).state = true;
      _setupMarkerListeners();
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing map: ${e.toString()}')),
        );
        // Set loading to false even on error to show the map
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupMarkerListeners() {
    final markerService = ref.read(markerServiceProvider);
    final markersNotifier = ref.read(markersProvider.notifier);

    markerService.getMarkersStream().listen((snapshot) async {
      final newMarkers = <Marker>{};
      for (final doc in snapshot.docs) {
        newMarkers
            .add(await markerService.createMarkerFromDoc(doc, _user.email!));
      }
      markersNotifier.addMarkers(newMarkers);
    });
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
      ),
      body: Column(
        children: [
          const MapHeader(),
          Expanded(
            child: MapView(
              markers: markers,
              circles: circles,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  currentPosition.latitude,
                  currentPosition.longitude,
                ),
                zoom: 16,
              ),
              onMapCreated: (controller) {
                _mapController.completeController(controller);
                controller.setMapStyle(mapstyle);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: MapFloatingControls(
        followUser: followUser,
        onFollowPressed: () {
          ref.read(followUserProvider.notifier).state = !followUser;
        },
        onAddMarkerPressed: () => _showMarkerTypeSelection(context),
        onPlaceSelected: _goToPlace,
      ),
    );
  }

  // We'll implement these methods in subsequent steps
  void _showMarkerTypeSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final types = ['plant', 'tree', 'mushroom', 'berry', 'other'];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child:
                  Text('Select a marker type', style: TextStyle(fontSize: 18)),
            ),
            Wrap(
              spacing: 10,
              children: types.map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: false,
                  onSelected: (_) {
                    Navigator.of(context).pop();
                    _showMarkerDetailsDialog(context, type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  void _showMarkerDetailsDialog(BuildContext context, String type) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add $type marker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Fetch current position
                final position = await MapPermissions.getCurrentPosition();

                // Save to Firestore
                final markerService =
                    MapMarkerService(FirebaseAuth.instance.currentUser!);
                await markerService.saveMarker(
                  name: nameController.text,
                  description: descriptionController.text,
                  type: type,
                  images: [], // Add image picker later if needed
                  position: position,
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // In map_page.dart
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
}
