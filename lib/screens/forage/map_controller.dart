import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'map_permissions.dart';

class MapController {
  final User currentUser;
  late StreamSubscription<Position> positionStream;
  Position? currentPosition;
  bool _followUser;

  MapController(this.currentUser, {bool followUser = false})
      : _followUser = followUser;

  bool get followUser => _followUser;
  set followUser(bool value) {
    if (_followUser != value) {
      _followUser = value;      
    }
  }

  Future<void> initialize() async {
    await _checkPermissions();
    currentPosition = await MapPermissions.getCurrentPosition();
    positionStream = MapPermissions.getPositionStream().listen(_onPositionUpdate);
  }

  Future<void> _checkPermissions() async {
    if (!await MapPermissions.checkLocationPermission()) {
      await MapPermissions.requestLocationPermission();
    }
  }

  void _onPositionUpdate(Position position) {
    currentPosition = position;
  }

  void dispose() {
    positionStream.cancel();
  }
}