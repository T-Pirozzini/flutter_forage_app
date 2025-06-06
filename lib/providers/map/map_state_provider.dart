import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Google Maps controller completer
final mapControllerProvider =
    Provider.autoDispose<Completer<GoogleMapController>>(
  (ref) => Completer<GoogleMapController>(),
);

// UI State Providers
final followUserProvider = StateProvider<bool>((ref) => true);
final lastManualMoveProvider = StateProvider<DateTime?>((ref) => null);

// Current position state
final currentPositionProvider =
    StateNotifierProvider<PositionNotifier, Position?>(
  (ref) => PositionNotifier(),
);

class PositionNotifier extends StateNotifier<Position?> {
  PositionNotifier() : super(null);

  void updatePosition(Position position) {
    state = position;
  }
}

// Map overlays
final markersProvider = StateNotifierProvider<MarkersNotifier, Set<Marker>>(
  (ref) => MarkersNotifier(ref), // Pass ref to MarkersNotifier
);

final circlesProvider = StateNotifierProvider<CirclesNotifier, Set<Circle>>(
  (ref) => CirclesNotifier(),
);

class MarkersNotifier extends StateNotifier<Set<Marker>> {
  final Ref _ref;
  StreamSubscription<QuerySnapshot>? _userMarkersSubscription;
  StreamSubscription<QuerySnapshot>? _communityMarkersSubscription;

  MarkersNotifier(this._ref) : super({}) {
    _init();
  }

  void _init() {
    final userId = FirebaseAuth.instance.currentUser?.email ?? '';
    if (userId.isEmpty) return;

    // Listen to user markers
    _userMarkersSubscription = FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Markers')
        .where('markerOwner', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      final markers = _createMarkersFromSnapshot(snapshot);
      updateMarkers(markers);
    });

    // Listen to community markers
    _communityMarkersSubscription = FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Markers')
        .where('markerOwner', isNotEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      final markers = _createMarkersFromSnapshot(snapshot);
      addMarkers(markers);
    });

    // Add current location marker
    _ref.listen(currentPositionProvider, (previous, next) {
      if (next != null) {
        final currentLocationMarker = Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(next.latitude, next.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );
        addMarkers({currentLocationMarker});
      }
    });
  }

  Set<Marker> _createMarkersFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final location = data['location'] as Map<String, dynamic>;
      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(
          (location['latitude'] as num).toDouble(),
          (location['longitude'] as num).toDouble(),
        ),
        infoWindow: InfoWindow(
          title: data['name'] ?? 'Unnamed',
          snippet: data['description'] ?? '',
        ),
        icon: _getMarkerIcon(data['type'] ?? ''),
      );
    }).toSet();
  }

  BitmapDescriptor _getMarkerIcon(String type) {
    switch (type.toLowerCase()) {
      case 'berries':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet);
      case 'mushrooms':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      case 'nuts':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet);
      case 'herbs':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'tree':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case 'fish':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void updateMarkers(Set<Marker> markers) => state = markers;
  void addMarkers(Set<Marker> markers) => state = {...state, ...markers};
  void removeMarkers(Set<MarkerId> ids) =>
      state = state.where((m) => !ids.contains(m.markerId)).toSet();

  @override
  void dispose() {
    _userMarkersSubscription?.cancel();
    _communityMarkersSubscription?.cancel();
    super.dispose();
  }
}

class CirclesNotifier extends StateNotifier<Set<Circle>> {
  CirclesNotifier() : super({});

  void updateCircles(Set<Circle> circles) => state = circles;
  void addCircles(Set<Circle> circles) => state = {...state, ...circles};
  void removeCircles(Set<String> ids) =>
      state = state.where((c) => !ids.contains(c.circleId.value)).toSet();
}
