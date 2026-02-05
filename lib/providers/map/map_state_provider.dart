import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/models/custom_marker_type.dart';
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

// Flag to track programmatic camera moves (prevents disabling follow on our own moves)
final isProgrammaticMoveProvider = StateProvider.autoDispose<bool>((ref) => false);

// Map bearing/rotation for compass display (0 = north, 90 = east, etc.)
final mapBearingProvider = StateProvider.autoDispose<double>((ref) => 0.0);

// Search mode - when true, hide most controls to give more space for suggestions
final isSearchFocusedProvider = StateProvider.autoDispose<bool>((ref) => false);

// Map type state (terrain, satellite, hybrid)
final mapTypeProvider = StateProvider.autoDispose<MapType>((ref) => MapType.terrain);

// Visible marker types filter (all visible by default)
// Used for real-time filtering of markers on the map
final visibleMarkerTypesProvider = StateProvider.autoDispose<Set<String>>((ref) {
  return ForageTypeUtils.allTypes.toSet();
});

// Spoof/test location for testing marker distances from a point user can't reach
// When set, distance calculations use this instead of real GPS
final spoofLocationProvider = StateProvider.autoDispose<LatLng?>((ref) => null);

// Whether spoof location is currently active
final isSpoofLocationActiveProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(spoofLocationProvider) != null;
});

// Effective location for distance calculations
// Returns spoof location if set, otherwise real GPS position as LatLng
final effectiveLocationProvider = Provider.autoDispose<LatLng?>((ref) {
  final spoofLocation = ref.watch(spoofLocationProvider);
  if (spoofLocation != null) return spoofLocation;

  final position = ref.watch(currentPositionProvider);
  if (position == null) return null;
  return LatLng(position.latitude, position.longitude);
});

// Custom marker types provider - streams user's custom types from Firestore
final customMarkerTypesProvider = StreamProvider.autoDispose<List<CustomMarkerType>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.email ?? '';
  if (userId.isEmpty) return Stream.value([]);

  final repo = ref.watch(customMarkerTypeRepositoryProvider);
  return repo.streamByUserId(userId);
});

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
  StreamSubscription? _friendsSubscription;

  // Store raw marker data for re-filtering when visibility changes
  List<_MarkerData> _userMarkerData = [];
  List<_MarkerData> _communityMarkerData = [];

  // Cache friends as Set for O(1) lookup
  Set<String> _friendEmailsCache = {};

  // Debounce timer to prevent excessive rebuilds
  Timer? _rebuildDebounce;

  MarkersNotifier(this._ref) : super({}) {
    _init();

    // Setup cleanup on disposal
    _ref.onDispose(() {
      _userMarkersSubscription?.cancel();
      _communityMarkersSubscription?.cancel();
      _friendsSubscription?.cancel();
      _rebuildDebounce?.cancel();
    });
  }

  void _init() {
    final userId = FirebaseAuth.instance.currentUser?.email ?? '';
    if (userId.isEmpty) return;

    // Get repositories
    final markerRepo = _ref.read(markerRepositoryProvider);
    final friendRepo = _ref.read(friendRepositoryProvider);

    // 1. Listen to user markers FIRST (fast, small dataset, show immediately)
    _userMarkersSubscription = markerRepo
        .streamByUserId(userId)
        .listen((markerModels) {
      _userMarkerData = markerModels.map((model) => _MarkerData(
        id: model.id,
        type: model.type,
        latitude: model.latitude,
        longitude: model.longitude,
        name: model.name,
        description: model.description,
      )).toList();
      _scheduleRebuild();
    });

    // 2. Listen to friends list and cache it (for visibility filtering)
    _friendsSubscription = friendRepo
        .streamFriends(userId)
        .listen((friends) {
      _friendEmailsCache = friends.map((f) => f.friendEmail).toSet();
      // Just rebuild with cached data, don't refetch community markers
      _scheduleRebuild();
    });

    // 3. DEFER community markers by 500ms (let map render with user markers first)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _communityMarkersSubscription = markerRepo
          .streamVisibleMarkers(
            viewerEmail: userId,
            friendEmails: _friendEmailsCache.toList(),
          )
          .listen((markerModels) {
        _communityMarkerData = markerModels
            .where((model) => model.markerOwner != userId)
            .map((model) => _MarkerData(
              id: model.id,
              type: model.type,
              latitude: model.latitude,
              longitude: model.longitude,
              name: model.name,
              description: model.description,
            )).toList();
        _scheduleRebuild();
      });
    });

    // Listen to filter changes for real-time filtering
    _ref.listen(visibleMarkerTypesProvider, (previous, next) {
      _scheduleRebuild();
    });

    // Add current location marker
    _ref.listen(currentPositionProvider, (previous, next) {
      if (next != null) {
        _scheduleRebuild();
      }
    });
  }

  /// Schedule a debounced rebuild (prevents excessive rebuilds)
  void _scheduleRebuild() {
    _rebuildDebounce?.cancel();
    _rebuildDebounce = Timer(const Duration(milliseconds: 100), () {
      if (mounted) _rebuildMarkers();
    });
  }

  /// Rebuild markers from stored data, applying current visibility filter
  void _rebuildMarkers() {
    final visibleTypes = _ref.read(visibleMarkerTypesProvider);
    final currentPosition = _ref.read(currentPositionProvider);

    // Create lowercase set for case-insensitive comparison
    final visibleTypesLower = visibleTypes.map((t) => t.toLowerCase()).toSet();

    final Set<Marker> filteredMarkers = {};

    // Filter user markers (case-insensitive type matching)
    for (final data in _userMarkerData) {
      if (visibleTypesLower.contains(data.type.toLowerCase())) {
        filteredMarkers.add(Marker(
          markerId: MarkerId(data.id),
          position: LatLng(data.latitude, data.longitude),
          infoWindow: InfoWindow(
            title: data.name,
            snippet: data.description,
          ),
          icon: ForageTypeUtils.getMarkerIcon(data.type),
        ));
      }
    }

    // Filter community markers (case-insensitive type matching)
    for (final data in _communityMarkerData) {
      if (visibleTypesLower.contains(data.type.toLowerCase())) {
        filteredMarkers.add(Marker(
          markerId: MarkerId(data.id),
          position: LatLng(data.latitude, data.longitude),
          infoWindow: InfoWindow(
            title: data.name,
            snippet: data.description,
          ),
          icon: ForageTypeUtils.getMarkerIcon(data.type),
        ));
      }
    }

    // Add current location marker (always visible)
    if (currentPosition != null) {
      filteredMarkers.add(Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(currentPosition.latitude, currentPosition.longitude),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    state = filteredMarkers;
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

/// Internal class for storing marker data before applying filters
class _MarkerData {
  final String id;
  final String type;
  final double latitude;
  final double longitude;
  final String name;
  final String description;

  _MarkerData({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.description,
  });
}
