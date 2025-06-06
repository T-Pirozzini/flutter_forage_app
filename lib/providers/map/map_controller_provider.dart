import 'dart:async';
import 'package:flutter_forager_app/providers/map/map_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final mapControllerProvider = Provider.autoDispose<MapController>((ref) {
  final controller = MapController(ref);
  ref.onDispose(() => controller.dispose());
  return controller;
});

class MapController {
  final Ref _ref;
  StreamSubscription<Position>? _positionStream;
  final Completer<GoogleMapController> _mapCompleter = Completer();
  Stream<Position> get positionStream => Geolocator.getPositionStream();

  MapController(this._ref);

  Future<void> initialize() async {
    await _checkPermissions();
    _setupPositionListener();
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

  void _setupPositionListener() async {
    final initialPosition = await getCurrentPosition();
    _ref.read(currentPositionProvider.notifier).updatePosition(initialPosition);

    _positionStream = positionStream.listen((position) {
      final followUser = _ref.read(followUserProvider);
      final lastManualMove = _ref.read(lastManualMoveProvider);

      if (followUser) {
        if (lastManualMove == null ||
            DateTime.now().difference(lastManualMove) > Duration(seconds: 2)) {
          _moveCameraToPosition(position);
        }
      }
    });
  }

  Future<void> _moveCameraToPosition(Position position) async {
    if (_mapCompleter.isCompleted) {
      final controller = await _mapCompleter.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          ),
        ),
      );
    }
  }

  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void completeController(GoogleMapController controller) {
    if (!_mapCompleter.isCompleted) {
      _mapCompleter.complete(controller);
    }
  }

  void dispose() {
    _positionStream?.cancel();
  }
}
