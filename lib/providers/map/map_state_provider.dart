import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Google Maps controller completer
final mapControllerProvider = Provider.autoDispose<Completer<GoogleMapController>>(
  (ref) => Completer<GoogleMapController>(),
);

// UI State Providers
final followUserProvider = StateProvider<bool>((ref) => true);
final lastManualMoveProvider = StateProvider<DateTime?>((ref) => null);

// Current position state
final currentPositionProvider = StateNotifierProvider<PositionNotifier, Position?>(
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
  (ref) => MarkersNotifier(),
);

final circlesProvider = StateNotifierProvider<CirclesNotifier, Set<Circle>>(
  (ref) => CirclesNotifier(),
);

class MarkersNotifier extends StateNotifier<Set<Marker>> {
  MarkersNotifier() : super({});

  void updateMarkers(Set<Marker> markers) => state = markers;
  void addMarkers(Set<Marker> markers) => state = {...state, ...markers};
  void removeMarkers(Set<MarkerId> ids) => 
      state = state.where((m) => !ids.contains(m.markerId)).toSet();
}

class CirclesNotifier extends StateNotifier<Set<Circle>> {
  CirclesNotifier() : super({});

  void updateCircles(Set<Circle> circles) => state = circles;
  void addCircles(Set<Circle> circles) => state = {...state, ...circles};
  void removeCircles(Set<String> ids) =>
      state = state.where((c) => !ids.contains(c.circleId.value)).toSet();
}