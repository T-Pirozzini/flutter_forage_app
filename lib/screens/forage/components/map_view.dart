import 'package:flutter/material.dart';
import 'package:flutter_forager_app/providers/map/map_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends ConsumerStatefulWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<Circle> circles;
  final void Function(GoogleMapController) onMapCreated;
  final LatLng? focusLocation;

  const MapView({
    super.key,
    required this.initialCameraPosition,
    required this.markers,
    required this.circles,
    required this.onMapCreated,
    this.focusLocation,
  });

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.focusLocation != null) {
        _moveToLocation(widget.focusLocation!);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusLocation != null &&
        widget.focusLocation != oldWidget.focusLocation) {
      _moveToLocation(widget.focusLocation!);
    }
  }

  Future<void> _moveToLocation(LatLng location) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(location, 16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapType = ref.watch(mapTypeProvider);
    final spoofLocation = ref.watch(spoofLocationProvider);

    // Add spoof location marker if active
    final allMarkers = Set<Marker>.from(widget.markers);
    if (spoofLocation != null) {
      allMarkers.add(Marker(
        markerId: const MarkerId('spoof_location'),
        position: spoofLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(
          title: 'Test Location',
          snippet: 'Distances calculated from here',
        ),
      ));
    }

    // Wrap in DragTarget to accept spoof location drops
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        // Get the position where the drag was dropped
        // We need to convert screen coordinates to map coordinates
        _handleSpoofDrop(context, details.offset);
      },
      builder: (context, candidateData, rejectedData) {
        final isDraggingOver = candidateData.isNotEmpty;

        return Stack(
          children: [
            GoogleMap(
              mapType: mapType,
              markers: allMarkers,
              circles: widget.circles,
              initialCameraPosition: widget.initialCameraPosition,
              onMapCreated: (controller) {
                _mapController = controller;
                widget.onMapCreated(controller); // Pass through to parent
                if (widget.focusLocation != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _moveToLocation(widget.focusLocation!);
                  });
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false, // Hide default zoom controls (using custom)
              padding: const EdgeInsets.only(bottom: 60, left: 10),
              onCameraMoveStarted: () {
                ref.read(followUserProvider.notifier).state = false;
              },
            ),
            // Show drop indicator when dragging over
            if (isDraggingOver)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.orange.withValues(alpha: 0.1),
                    child: const Center(
                      child: Icon(
                        Icons.location_on,
                        size: 48,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Handle dropping the spoof location target onto the map
  void _handleSpoofDrop(BuildContext context, Offset screenPosition) async {
    if (_mapController == null) return;

    // Get the visible region to calculate approximate coordinates
    final visibleRegion = await _mapController!.getVisibleRegion();
    final screenSize = MediaQuery.of(context).size;

    // Calculate the lat/lng from screen position
    // This is an approximation based on the visible region
    final latRange = visibleRegion.northeast.latitude - visibleRegion.southwest.latitude;
    final lngRange = visibleRegion.northeast.longitude - visibleRegion.southwest.longitude;

    final lat = visibleRegion.northeast.latitude - (screenPosition.dy / screenSize.height) * latRange;
    final lng = visibleRegion.southwest.longitude + (screenPosition.dx / screenSize.width) * lngRange;

    final spoofLatLng = LatLng(lat, lng);
    ref.read(spoofLocationProvider.notifier).state = spoofLatLng;
    ref.read(followUserProvider.notifier).state = false;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test location set - distances calculated from here'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
