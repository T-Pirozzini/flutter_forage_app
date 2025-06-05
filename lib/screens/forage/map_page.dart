import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/components/ad_mob_service.dart';
import 'package:flutter_forager_app/screens/forage/map_permissions.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_location_info_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_forager_app/screens/forage/map_style.dart';
import 'map_controller.dart';
import 'map_markers.dart';
import 'map_ui.dart';
import 'map_view.dart'; // Import the new MapView widget

class MapPage extends StatefulWidget {
  final double lat;
  final double lng;
  final bool followUser;

  const MapPage({
    super.key,
    required this.lat,
    required this.lng,
    required this.followUser,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _mapController;
  late final MapMarkerService _markerService;
  final Completer<GoogleMapController> _mapCompleter = Completer();
  GoogleMapController? _mapControllerInstance;
  late CameraPosition _initialCameraPosition;
  final currentUser = FirebaseAuth.instance.currentUser!;
  final List<StreamSubscription> _firestoreSubscriptions = [];

  // Marker state
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  late Marker _currentPositionMarker;
  bool _isLoading = true;
  Position? currentLocation;

  @override
  void initState() {
    super.initState();
    _markerService = MapMarkerService(currentUser);
    _mapController = MapController(currentUser, followUser: widget.followUser);
    _initialCameraPosition = CameraPosition(
      target: LatLng(widget.lat, widget.lng),
      zoom: 14,
    );
    _initializeMap(); // _syncFollowUser will be called inside _initializeMap

    _currentPositionMarker = Marker(
      markerId: const MarkerId('currentPosition'),
      position: LatLng(widget.lat, widget.lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      zIndex: 100,
    );
    _markers.add(_currentPositionMarker);
  }

  Future<void> _initializeMap() async {
    try {
      await _mapController.initialize();
      if (!await MapPermissions.checkLocationPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Location permission denied. Please enable it in settings.'),
              action: SnackBarAction(
                label: 'Open Settings',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
        return;
      }
      setState(() {
        _initialCameraPosition = CameraPosition(
          target: LatLng(widget.lat, widget.lng),
          zoom: 14,
        );
        _isLoading = false;
      });

      // Set up listeners
      _setupPositionListener();
      _setupMarkerListeners();
      _syncFollowUser(); // Moved here to ensure currentPosition is set
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing map: $e')),
        );
      }
    }
  }

  void _setupPositionListener() {
    Geolocator.getPositionStream().listen((position) {
      _updateCurrentPositionMarker(position);
      if (_mapController.followUser) {
        _moveCameraToPosition(position);
      }
    });
  }

  void _syncFollowUser() {
    if (_mapController.followUser) {
      _moveCameraToPosition(_mapController.currentPosition).catchError((e) {
        debugPrint('Error syncing initial followUser: $e');
      });
    }
  }

  void _setupMarkerListeners() {
    final userSub = FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.email)
        .collection('Markers')
        .snapshots()
        .listen(
            (snapshot) => _processMarkerSnapshot(snapshot, currentUser.email!));
    _firestoreSubscriptions.add(userSub);

    final friendsSub = FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.email)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.data()?['friends'] != null) {
        final friends = snapshot.data()!['friends'] as List<dynamic>;
        for (final friend in friends) {
          String friendEmail;
          if (friend is String) {
            friendEmail = friend;
          } else if (friend is Map<String, dynamic>) {
            friendEmail = friend['email'] as String;
          } else {
            debugPrint('Unexpected friend data type: $friend');
            continue;
          }
          final friendSub = FirebaseFirestore.instance
              .collection('Users')
              .doc(friendEmail)
              .collection('Markers')
              .snapshots()
              .listen(
                  (snapshot) => _processMarkerSnapshot(snapshot, friendEmail));
          _firestoreSubscriptions.add(friendSub);
        }
      }
    });
    _firestoreSubscriptions.add(friendsSub);
  }

  void _updateCurrentPositionMarker(Position position) {
    final updatedMarker = Marker(
      markerId: _currentPositionMarker.markerId,
      position: LatLng(position.latitude, position.longitude),
      icon: _currentPositionMarker.icon,
      zIndex: _currentPositionMarker.zIndex,
    );

    if (mounted) {
      setState(() {
        _markers.remove(_currentPositionMarker);
        _markers.add(updatedMarker);
        _currentPositionMarker = updatedMarker;
      });
    }
  }

  Future<void> _moveCameraToPosition(Position? position) async {
    if (position == null) {
      debugPrint('Cannot move camera: Position is null');
      return;
    }
    final controller = await _mapCompleter.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      ),
    );
  }

  void _processMarkerSnapshot(QuerySnapshot snapshot, String ownerEmail) {
    setState(() {
      final markerIdsInSnapshot =
          snapshot.docs.map((doc) => doc['name'] as String).toSet();
      _markers
          .removeWhere((m) => markerIdsInSnapshot.contains(m.markerId.value));
      _circles.removeWhere((c) => markerIdsInSnapshot
          .contains(c.circleId.value.replaceFirst('circle_', '')));
    });

    for (final doc in snapshot.docs) {
      _addMarkerFromData(doc.data() as Map<String, dynamic>, ownerEmail);
    }
  }

  Future<void> _addMarkerFromData(
      Map<String, dynamic> data, String ownerEmail) async {
    try {
      final location = data['location'] as Map<String, dynamic>;
      final latLng = LatLng(
        (location['latitude'] as num).toDouble(),
        (location['longitude'] as num).toDouble(),
      );

      final markerId = MarkerId(data['name']);

      if (_markers.any((m) => m.markerId == markerId)) return;

      final marker = Marker(
        markerId: markerId,
        position: latLng,
        icon: await _markerService.getMarkerIcon(data['type'] ?? 'plant'),
        infoWindow: InfoWindow(
          title: data['name'] ?? 'Unnamed Location',
          snippet: '(tap for details)',
          onTap: () => _showMarkerDetails(
            name: data['name'],
            description: data['description'],
            lat: latLng.latitude,
            lng: latLng.longitude,
            type: data['type'],
            owner: ownerEmail,
            imageUrls: (data['image'] != null) ? [data['image'] as String] : [],
          ),
        ),
      );

      final circle = Circle(
        circleId: CircleId('circle_${data['name']}'),
        center: latLng,
        radius: 200,
        fillColor: Colors.pinkAccent.withOpacity(0.3),
        strokeColor: Colors.pinkAccent,
        strokeWidth: 2,
      );

      if (mounted) {
        setState(() {
          _markers.add(marker);
          _circles.add(circle);
        });
      }
    } catch (e) {
      debugPrint('Error adding marker: $e');
    }
  }

  void _showMarkerDetails({
    required String? name,
    required String? description,
    required double lat,
    required double lng,
    required String? type,
    required String owner,
    required List<String> imageUrls,
  }) {
    AdMobService.showInterstitialAd();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForageLocationInfo(
          name: name ?? 'Unnamed Location',
          description: description ?? '',
          lat: lat,
          lng: lng,
          timestamp: DateTime.now().toString(),
          type: type ?? 'plant',
          markerOwner: owner,
          imageUrls: imageUrls,
        ),
      ),
    );
  }

  void _showMarkerTypeSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Marker Type', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMarkerTypeButton(
                    context, 'Plant', 'lib/assets/images/plant_marker.png'),
                _buildMarkerTypeButton(
                    context, 'Berries', 'lib/assets/images/berries_marker.png'),
                _buildMarkerTypeButton(context, 'Mushroom',
                    'lib/assets/images/mushroom_marker.png'),
                _buildMarkerTypeButton(
                    context, 'Tree', 'lib/assets/images/tree_marker.png'),
                _buildMarkerTypeButton(
                    context, 'Fish', 'lib/assets/images/fish_marker.png'),
                _buildMarkerTypeButton(context, 'Shellfish',
                    'lib/assets/images/shellfish_marker.png'),
                _buildMarkerTypeButton(
                    context, 'Nuts', 'lib/assets/images/nuts_marker.png'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerTypeButton(
      BuildContext context, String type, String imagePath) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _showAddMarkerDialog(type);
      },
      child: Column(
        children: [
          Image.asset(imagePath, width: 50, height: 50),
          const SizedBox(height: 4),
          Text(type),
        ],
      ),
    );
  }

  Future<Position> _getCurrentPosition() async {
    final location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return location;

    setState(() {
      currentLocation = location;
    });
    return location;
  }

  Future<void> _showAddMarkerDialog(String markerType) async {
    final position = await _getCurrentPosition();
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    File? selectedImage;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add $markerType Location'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Location Name'),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  if (selectedImage != null)
                    Image.file(selectedImage!, height: 100),
                  ElevatedButton(
                    onPressed: () async {
                      final image = await ImagePicker()
                          .pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() => selectedImage = File(image.path));
                      }
                    },
                    child: const Text('Add Image'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _markerService.saveMarker(
                      name: nameController.text,
                      description: descController.text,
                      type: markerType,
                      images: selectedImage != null ? [selectedImage!] : [],
                      position: position,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location saved successfully!'),
                        ),
                      );
                    }
                    Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving location: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToPlace(Map<String, dynamic> place) async {
    _mapController.followUser = false;
    final double lat = place['geometry']['location']['lat'];
    final double lng = place['geometry']['location']['lng'];
    final controller = await _mapCompleter.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 14,
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapControllerInstance = controller;
    _mapCompleter.complete(controller);
    controller.setMapStyle(mapstyle);
  }

  @override
  void dispose() {
    _mapControllerInstance?.dispose();
    for (var sub in _firestoreSubscriptions) {
      sub.cancel();
    }
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forage Map'),
      ),
      body: Column(
        children: [
          const MapHeader(),
          Expanded(
            child: MapView(
              // Replace GoogleMap with MapView
              initialCameraPosition: _initialCameraPosition,
              markers: _markers,
              circles: _circles,
              onMapCreated: _onMapCreated,
            ),
          ),
        ],
      ),
      floatingActionButton: MapFloatingControls(
        followUser: _mapController.followUser,
        onFollowPressed: () async {
          setState(() {
            _mapController.followUser = !_mapController.followUser;
          });
          if (_mapController.followUser) {
            await _moveCameraToPosition(_mapController.currentPosition);
          }
        },
        onAddMarkerPressed: () => _showMarkerTypeSelection(context),
        onPlaceSelected: _goToPlace,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
    );
  }
}
