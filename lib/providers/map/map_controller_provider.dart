import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/providers/map/map_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final mapControllerProvider = Provider<MapController>((ref) {
  final controller = MapController(ref);
  ref.onDispose(() => controller.dispose());
  return controller;
});

class MapController {
  final Ref _ref;
  StreamSubscription<Position>? _positionStream;
  final Completer<GoogleMapController> _mapCompleter = Completer();
  GoogleMapController? _controller;
  bool _isDisposed = false;
  Stream<Position> get positionStream => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Only update when moved 10+ meters (battery optimization)
    ),
  );

  MapController(this._ref);

  Future<void> initialize() async {
    await _checkPermissions();
    await _setupPositionListener();
  }

  Future<void> _checkPermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services are disabled');
    }

    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  Future<void> _setupPositionListener() async {
    try {
      final initialPosition = await getCurrentPosition();
      _ref.read(currentPositionProvider.notifier).updatePosition(initialPosition);

      _positionStream = positionStream.listen(
        (position) {
          final followUser = _ref.read(followUserProvider);
          final lastManualMove = _ref.read(lastManualMoveProvider);

          if (followUser) {
            if (lastManualMove == null ||
                DateTime.now().difference(lastManualMove) > const Duration(seconds: 2)) {
              _moveCameraToPosition(position);
            }
          }
        },
        onError: (error) {
          debugPrint('Position stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to setup position listener: $e');
      rethrow;
    }
  }

  Future<void> _moveCameraToPosition(Position position) async {
    if (_isDisposed || !_mapCompleter.isCompleted || _controller == null) {
      return;
    }

    try {
      await _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          ),
        ),
      );
    } catch (e) {
      // Ignore camera animation errors (e.g., when map is disposed)
      return;
    }
  }

  Future<void> moveToLocation(LatLng target, {double zoom = 14}) async {
    if (_isDisposed || !_mapCompleter.isCompleted || _controller == null) {
      return;
    }

    try {
      await _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: zoom,
          ),
        ),
      );
    } catch (e) {
      // Ignore camera animation errors (e.g., when map is disposed)
      return;
    }
  }

  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void completeController(GoogleMapController controller) {
    if (!_mapCompleter.isCompleted && !_isDisposed) {
      _controller = controller;
      _mapCompleter.complete(controller);
    }
  }

  void dispose() {
    _isDisposed = true;
    _positionStream?.cancel();
    _controller?.dispose();
    _controller = null;
  }
}
