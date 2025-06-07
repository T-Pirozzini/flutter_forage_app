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
    return GoogleMap(
      mapType: MapType.terrain,
      markers: widget.markers,
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
      padding: const EdgeInsets.only(bottom: 60, left: 10),
      onCameraMoveStarted: () {
        ref.read(followUserProvider.notifier).state = false;
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
