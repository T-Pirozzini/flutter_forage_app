import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/components/map_style.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../components/search_field.dart';

class MapPage extends StatefulWidget {
  final double lat;
  final double lng;
  final bool followUser;
  const MapPage(
      {super.key,
      required this.lat,
      required this.lng,
      required this.followUser});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  late StreamSubscription<Position> _positionStreamSubscription;
  late Marker _currentPositionMarker;

  // get current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  // create set of markers
  final Set<Marker> _markers = {};

  Position? currentLocation;
  late CameraPosition _kGooglePlex;
  bool followUser = false;

  @override
  void initState() {
    _currentPositionMarker = Marker(
      markerId: const MarkerId('currentPosition'),
      infoWindow: const InfoWindow(title: 'Current Position'),
      position: const LatLng(0, 0),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );
    _markers.add(_currentPositionMarker);
    _positionStreamSubscription =
        Geolocator.getPositionStream().listen(_onPositionUpdate);
    // get position
    _getCurrentPosition();
    // fetch initial marker data
    fetchMarkerData();
    _kGooglePlex = CameraPosition(
      target: LatLng(widget.lat, widget.lng),
      zoom: 14,
    );
    followUser = widget.followUser;
    super.initState();
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    super.dispose();
  }

  void _onPositionUpdate(Position position) async {
    if (!mounted) return;
    final GoogleMapController controller = await _controller.future;
    if (followUser) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          ),
        ),
      );
    }
    final updatedMarker = Marker(
      markerId: _currentPositionMarker.markerId,
      infoWindow: _currentPositionMarker.infoWindow,
      position: LatLng(position.latitude, position.longitude),
      icon: _currentPositionMarker.icon,
      zIndex: 100.0,
    );

    setState(() {
      _markers.remove(_currentPositionMarker);
      _markers.add(updatedMarker);
      _currentPositionMarker = updatedMarker;
    });
  }

  // final CameraPosition _kGooglePlex = CameraPosition(
  //   target: LatLng(lat, lng),
  //   zoom: 14,
  // );

  // get current position
  Future<Position> _getCurrentPosition() async {
    final location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      currentLocation = location;
    });
    return location;
  }

  // get current users marker data
  void fetchMarkerData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.email)
        .collection('Markers')
        .get();

    final docs = snapshot.docs;

    // // Process each document and add markers
    for (final doc in docs) {
      final data = doc.data();
      final name = data['name'] as String;
      final description = data['description'] as String;

      // Retrieve the latitude and longitude as doubles
      final location = data['location'] as Map<String, dynamic>;
      final latitude = location['latitude'] as double;
      final longitude = location['longitude'] as double;
      final type = data['type'] as String;

      addMarker(
        name: name,
        description: description,
        location: LatLng(latitude, longitude),
        type: type,
      );
    }

    // Subscribe to collection changes for real-time updates
    FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.email)
        .collection('Markers')
        .snapshots()
        .listen((snapshot) {
      _markers.clear(); // Clear existing markers
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String;
        final description = data['description'] as String;
        final latitude = data['location']['latitude'] as double;
        final longitude = data['location']['longitude'] as double;
        final type = data['type'] as String;

        addMarker(
          name: name,
          description: description,
          location: LatLng(latitude, longitude),
          type: type,
        );
      }
    });
  }

  // add markers
  Future<void> addMarker({
    required String name,
    required String description,
    required LatLng location,
    required String type,
  }) async {
    final markerId = MarkerId(name);
    final marker = Marker(
      markerId: markerId,
      infoWindow: InfoWindow(title: name, snippet: description),
      position: location,
      icon: await getMarkerIcon(type),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  // get marker icon
  Future<BitmapDescriptor> getMarkerIcon(String type) async {
    const double markerSize = 2.0;
    return BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(markerSize, markerSize)),
      'lib/assets/images/${type.toLowerCase()}_marker.png',
    );
  }

  // go to place
  Future<void> _goToPlace(Map<String, dynamic> place) async {
    final double lat = place['geometry']['location']['lat'];
    final double lng = place['geometry']['location']['lng'];
    final GoogleMapController controller = await _controller.future;
    final newCameraPosition = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 14,
    );
    controller.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    // bool _followUser = followUser;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              markers: _markers,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                controller.setMapStyle(mapstyle);
              },
              padding: const EdgeInsets.only(bottom: 60),
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 140.0,
            right: -8.0,
            child: FloatingActionButton(
              onPressed: () {
                setState(
                  () {
                    followUser = !followUser;
                  },
                );
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
          Positioned(
            top: 20,
            left: 20,
            right: -50,
            child: Container(
              margin: const EdgeInsets.only(right: 150),
              child: Row(
                children: [
                  Expanded(
                    child: SearchField(
                      onPlaceSelected: _goToPlace,
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
