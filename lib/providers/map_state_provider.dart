import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

final mapControllerProvider = Provider.autoDispose<Completer<GoogleMapController>>(
  (ref) => Completer<GoogleMapController>(),
);

final markersProvider = StateNotifierProvider<MarkersNotifier, Set<Marker>>(
  (ref) => MarkersNotifier(),
);

class MarkersNotifier extends StateNotifier<Set<Marker>> {
  MarkersNotifier() : super({});

  void addMarkers(Set<Marker> markers) {
    state = {...state, ...markers};
  }

  void removeMarkers(Set<MarkerId> markerIds) {
    state = state.where((marker) => !markerIds.contains(marker.markerId)).toSet();
  }

  void clearMarkers() {
    state = {};
  }
}

final circlesProvider = StateNotifierProvider<CirclesNotifier, Set<Circle>>(
  (ref) => CirclesNotifier(),
);

class CirclesNotifier extends StateNotifier<Set<Circle>> {
  CirclesNotifier() : super({});

  void addCircles(Set<Circle> circles) {
    state = {...state, ...circles};
  }

  void removeCircles(Set<String> circleIds) {
    state = state.where((circle) => !circleIds.contains(circle.circleId.value)).toSet();
  }
}

final followUserProvider = StateProvider<bool>((ref) => true);