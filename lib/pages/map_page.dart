import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/components/map_style.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  late StreamSubscription<Position> _positionStreamSubscription;
  late Marker _currentPositionMarker;

  @override
  void initState() {
    _currentPositionMarker = Marker(
      markerId: const MarkerId('currentPosition'),
      infoWindow: const InfoWindow(title: 'Current Position'),
      position: const LatLng(0, 0),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );
    _positionStreamSubscription =
        Geolocator.getPositionStream().listen(_onPositionUpdate);
    super.initState();
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    super.dispose();
  }

  bool _followUser = true;
  void _onPositionUpdate(Position position) async {
    final GoogleMapController controller = await _controller.future;
    if (_followUser) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          ),
        ),
      );
    }
    setState(() {
      _currentPositionMarker = _currentPositionMarker.copyWith(
        positionParam: LatLng(position.latitude, position.longitude),
      );
    });
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14,
  );

  bool _isPressed = false;
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _isPressed = false;
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      ),
    );
    return position;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              markers: {
                _currentPositionMarker,
              },
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
            top: 30.0,
            right: 5.0,
            child: FloatingActionButton(
              onPressed: () {
                setState(
                  () {
                    _isPressed = true;
                  },
                );
                _determinePosition().then((position) {
                  setState(() {
                    _isPressed = false;
                  });
                });
              },
              shape: const RoundedRectangleBorder(),
              mini: true,
              backgroundColor: Colors.grey.shade800,
              child: Icon(
                Icons.my_location,
                color: _isPressed ? Colors.deepOrange.shade300 : Colors.white,
              ),
            ),
          ),
          Positioned(
            top: 80.0,
            right: 5.0,
            child: FloatingActionButton(
              onPressed: () {
                setState(
                  () {
                    _followUser = !_followUser;
                  },
                );
              },
              shape: const RoundedRectangleBorder(),
              mini: true,
              backgroundColor: Colors.grey.shade800,
              child: Icon(
                Icons.person,
                color: _followUser ? Colors.deepOrange.shade300 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
