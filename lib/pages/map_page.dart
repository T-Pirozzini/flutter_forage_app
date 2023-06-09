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

  Position? currentLocation;

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
    // get position
    _getCurrentPosition();
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
          Padding(
            padding: const EdgeInsets.only(bottom: 200.0),
            child: Text(
              'Current location: $currentLocation',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            top: 30.0,
            right: 0.0,
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
                Icons.my_location,
                color: _followUser ? Colors.deepOrange.shade300 : Colors.white,
              ),
            ),
          ),

          // const Positioned(
          //   bottom: 60.0,
          //   left: 30.0,
          //   child: MarkerButtons(
          //     currentPosition: LatLng(37.42796133580664, -122.085749655962),
          //   ),
          // ),
        ],
      ),
    );
  }
}
