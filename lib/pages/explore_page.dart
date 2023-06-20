import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/components/map_style.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../components/search_field.dart';

class ExplorePage extends StatefulWidget {  

  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => ExplorePageState();
}

class ExplorePageState extends State<ExplorePage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  late CameraPosition _initialCameraPosition;

  @override
  void initState() {
    super.initState();    
    _determinePosition();
    _initialCameraPosition = CameraPosition(
      target: const LatLng(0, 0),
      zoom: 14.0,
    );
  }

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
    if (mounted) {
      setState(
        () {
          _isPressed = false;
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14.0,
          );
        },
      );
    }

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14,
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
          Row(
            children: [
              Expanded(
                child: SearchField(
                  onPlaceSelected: _goToPlace,
                ),
              ),
            ],
          ),
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              markers: const {},
              initialCameraPosition: _initialCameraPosition,
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
            top: 80.0,
            right: 5.0,
            child: FloatingActionButton(
              onPressed: () {
                setState(
                  () {
                    _isPressed = true;
                  },
                );
                _determinePosition();
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
        ],
      ),
    );
  }
}
