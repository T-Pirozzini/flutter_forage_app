import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Google Maps controller completer (renamed to avoid conflict with MapController provider)
final mapCompleterProvider =
    Provider.autoDispose<Completer<GoogleMapController>>(
  (ref) => Completer<GoogleMapController>(),
);

// UI State Providers (autoDispose to prevent memory leaks when leaving map)
final followUserProvider = StateProvider.autoDispose<bool>((ref) => true);
final lastManualMoveProvider = StateProvider.autoDispose<DateTime?>((ref) => null);

// Current position state (autoDispose to clean up when map is closed)
final currentPositionProvider =
    StateNotifierProvider.autoDispose<PositionNotifier, Position?>(
  (ref) => PositionNotifier(),
);

class PositionNotifier extends StateNotifier<Position?> {
  PositionNotifier() : super(null);

  void updatePosition(Position position) {
    state = position;
  }
}

// Map overlays
final markersProvider = StateNotifierProvider.autoDispose<MarkersNotifier, Set<Marker>>(
  (ref) => MarkersNotifier(ref), // Pass ref to MarkersNotifier
);

final circlesProvider = StateNotifierProvider<CirclesNotifier, Set<Circle>>(
  (ref) => CirclesNotifier(),
);

class MarkersNotifier extends StateNotifier<Set<Marker>> {
  final Ref _ref;
  StreamSubscription? _userMarkersSubscription;
  StreamSubscription? _communityMarkersSubscription;

  MarkersNotifier(this._ref) : super({}) {
    _init();

    // Setup cleanup on disposal
    _ref.onDispose(() {
      _userMarkersSubscription?.cancel();
      _communityMarkersSubscription?.cancel();
    });
  }

  void _init() {
    final userId = FirebaseAuth.instance.currentUser?.email ?? '';
    if (userId.isEmpty) return;

    // Get marker repository
    final markerRepo = _ref.read(markerRepositoryProvider);

    // Listen to user markers using repository
    _userMarkersSubscription = markerRepo
        .streamByUserId(userId)
        .listen((markerModels) {
      final markers = markerModels.map((model) {
        return Marker(
          markerId: MarkerId(model.id),
          position: LatLng(model.latitude, model.longitude),
          infoWindow: InfoWindow(
            title: model.name,
            snippet: model.description,
          ),
          icon: ForageTypeUtils.getMarkerIcon(model.type),
        );
      }).toSet();
      updateMarkers(markers);
    });

    // Listen to community markers (all markers not owned by user)
    _communityMarkersSubscription = markerRepo
        .streamPublicMarkers()
        .listen((markerModels) {
      final communityMarkers = markerModels
          .where((model) => model.markerOwner != userId)
          .map((model) {
        return Marker(
          markerId: MarkerId(model.id),
          position: LatLng(model.latitude, model.longitude),
          infoWindow: InfoWindow(
            title: model.name,
            snippet: model.description,
          ),
          icon: ForageTypeUtils.getMarkerIcon(model.type),
        );
      }).toSet();
      addMarkers(communityMarkers);
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
