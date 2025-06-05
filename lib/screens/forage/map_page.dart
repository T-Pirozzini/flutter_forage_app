import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/forage/components/map_markers.dart';
import 'package:flutter_forager_app/screens/forage/components/map_style.dart';
import 'package:flutter_forager_app/screens/forage/services/map_permissions.dart';
import 'package:flutter_forager_app/screens/forage/services/marker_service.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_forager_app/screens/forage/components/map_ui.dart';
import 'package:flutter_forager_app/screens/forage/components/map_view.dart';
import 'package:flutter_forager_app/screens/forage/services/map_controller.dart';
import 'package:flutter_forager_app/providers/map_state_provider.dart';

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
    _mapController = MapController(FirebaseAuth.instance.currentUser!);
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      await _mapController.initialize();
      final position = await _mapController.getCurrentPosition();
      _mapController.initialPosition = position;

      ref.read(followUserProvider.notifier).state = true;
      _setupPositionListener();
      _setupMarkerListeners();

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing map: $e')),
        );
      }
    }
  }

  void _setupPositionListener() {
    _mapController.positionStream.listen((position) {
      if (ref.read(followUserProvider)) {
        _moveCameraToPosition(position);
      }
    });
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

  Future<void> _moveCameraToPosition(Position position) async {
    final controller = await ref.read(mapControllerProvider).future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      ),
    );
  }

  Future<void> _saveMarker({
    required String name,
    required String description,
    required String type,
    required Position position,
  }) async {
    try {
      final markerService = ref.read(markerServiceProvider);
      await markerService.saveMarker(
        name: name,
        description: description,
        type: type,
        position: position,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving location: $e')),
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = ref.watch(markersProvider);
    final circles = ref.watch(circlesProvider);
    final followUser = ref.watch(followUserProvider);

    if (_isLoading) {
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
                  _mapController.initialPosition.latitude,
                  _mapController.initialPosition.longitude,
                ),
                zoom: 16,
              ),
              onMapCreated: (controller) {
                ref.read(mapControllerProvider).complete(controller);
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

  Future<void> _goToPlace(Map<String, dynamic> place) async {}
}
