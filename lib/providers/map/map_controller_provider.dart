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
      // 1. Try instant cached position first (non-blocking)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _ref.read(currentPositionProvider.notifier).updatePosition(lastKnown);
        debugPrint('Using cached position: ${lastKnown.latitude}, ${lastKnown.longitude}');
      }

      // 2. Get accurate position in background (don't block map loading)
      Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .then((accuratePosition) {
        if (_isDisposed) return;
        _ref.read(currentPositionProvider.notifier).updatePosition(accuratePosition);
        debugPrint('Got accurate position: ${accuratePosition.latitude}, ${accuratePosition.longitude}');

        // Animate to accurate position if still following user
        if (_ref.read(followUserProvider)) {
          _moveCameraToPosition(accuratePosition);
        }
      }).catchError((e) {
        debugPrint('Failed to get accurate position: $e');
      });

      // 3. Start continuous position stream
      _positionStream = positionStream.listen(
        (position) {
          if (_isDisposed) return;
          _ref.read(currentPositionProvider.notifier).updatePosition(position);

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

  /// Zoom in one level
  Future<void> zoomIn() async {
    if (_isDisposed || _controller == null) {
      debugPrint('ZoomIn: controller not ready (disposed: $_isDisposed, controller: $_controller)');
      return;
    }

    try {
      await _controller!.animateCamera(CameraUpdate.zoomIn());
    } catch (e) {
      debugPrint('ZoomIn error: $e');
    }
  }

  /// Zoom out one level
  Future<void> zoomOut() async {
    if (_isDisposed || _controller == null) {
      debugPrint('ZoomOut: controller not ready (disposed: $_isDisposed, controller: $_controller)');
      return;
    }

    try {
      await _controller!.animateCamera(CameraUpdate.zoomOut());
    } catch (e) {
      debugPrint('ZoomOut error: $e');
    }
  }

  void completeController(GoogleMapController controller) {
    _controller = controller; // Always set the controller
    if (!_mapCompleter.isCompleted && !_isDisposed) {
      _mapCompleter.complete(controller);
    }
    debugPrint('MapController: completeController called, controller set');
  }

  void dispose() {
    _isDisposed = true;
    _positionStream?.cancel();
    _controller?.dispose();
    _controller = null;
  }
}
