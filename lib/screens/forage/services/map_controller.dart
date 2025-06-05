import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_forager_app/screens/forage/services/map_permissions.dart';

class MapController {
  final User currentUser;
  late StreamSubscription<Position> _positionStream;
  late Position initialPosition;
  Position? currentPosition;
  Stream<Position> get positionStream => Geolocator.getPositionStream();

  MapController(this.currentUser);

  Future<void> initialize() async {
    await _checkPermissions();
    currentPosition = await getCurrentPosition();
  }

  Future<Position> getCurrentPosition() async {
    return await MapPermissions.getCurrentPosition();
  }

  Future<void> _checkPermissions() async {
    if (!await MapPermissions.checkLocationPermission()) {
      await MapPermissions.requestLocationPermission();
    }
  }

  void dispose() {
    _positionStream.cancel();
  }
}
