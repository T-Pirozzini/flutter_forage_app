import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_forager_app/screens/forage/search_field.dart';

class MapFloatingControls extends StatelessWidget {
  final bool followUser;
  final VoidCallback onFollowPressed;
  final VoidCallback onAddMarkerPressed;
  final Function(Map<String, dynamic>) onPlaceSelected;

  const MapFloatingControls({
    super.key,
    required this.followUser,
    required this.onFollowPressed,
    required this.onAddMarkerPressed,
    required this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 250,
          left: 20,
          right: 20,
          child: SearchField(
            onPlaceSelected: onPlaceSelected,
          ),
        ),
        Positioned(
          bottom: 145.0,
          right: 18.0,
          child: FloatingActionButton(
            heroTag: 'locationButton',
            onPressed: onFollowPressed,
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
          bottom: 80.0,
          left: 18.0,
          child: FloatingActionButton(
            heroTag: 'add_marker_fab',
            onPressed: onAddMarkerPressed,
            backgroundColor: Colors.deepOrange.shade300,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class MapHeader extends StatelessWidget {
  const MapHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: const Column(
        children: [
          Text("Explore your local area for forageable ingredients."),
          Text('Mark the location so you can find it again!'),
        ],
      ),
    );
  }
}
