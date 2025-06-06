import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<Circle> circles;
  final void Function(GoogleMapController) onMapCreated;

  const MapView({
    super.key,
    required this.initialCameraPosition,
    required this.markers,
    required this.circles,
    required this.onMapCreated,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: MapType.terrain,
      markers: widget.markers,
      circles: widget.circles,
      initialCameraPosition: widget.initialCameraPosition,
      onMapCreated: widget.onMapCreated,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      padding: const EdgeInsets.only(bottom: 60, left: 10),
    );
  }
}