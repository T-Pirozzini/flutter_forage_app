import 'dart:async';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forager_app/components/ad_mob_service.dart';
import 'package:flutter_forager_app/screens/forage/map_style.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_locations_page.dart';
import 'package:flutter_forager_app/screens/home/home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'search_field.dart';

class MapPage extends StatefulWidget {
  final double lat;
  final double lng;
  final bool followUser;
  const MapPage(
      {super.key,
      required this.lat,
      required this.lng,
      required this.followUser});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  late StreamSubscription<Position> _positionStreamSubscription;
  late Marker _currentPositionMarker;

  // Method to request location permissions
  void _requestLocationPermission() async {
    // Check if the permission is already granted
    if (await Permission.location.isGranted) {
      // If already granted, proceed with location-based operations
      _onLocationPermissionGranted();
      return;
    }

    // Request the permission
    final permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      // If the user grants the permission, proceed with location-based operations
      _onLocationPermissionGranted();
    } else {
      // If the user denies the permission, handle this case gracefully (show an error, prompt to grant permission again, etc.)
      // For example, you can display a SnackBar or showDialog to inform the user.
      print('Location permission denied.');
    }
  }

  void _onLocationPermissionGranted() async {
    // You can add any location-based operations that require the user's permission here.
    // For example, fetch the user's current location, set up geolocation services, etc.

    // Fetch the user's current position
    await _getCurrentPosition();

    // Fetch marker data based on the user's location
    fetchMarkerData();
  }

  // get current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  // create set of markers
  final Set<Marker> _markers = {};

  // create set of circles
  final Set<Circle> _circles = {};

  Position? currentLocation;
  late CameraPosition _kGooglePlex;
  bool followUser = false;

  @override
  void initState() {
    // Request location permissions
    _requestLocationPermission();
    _currentPositionMarker = Marker(
      markerId: const MarkerId('currentPosition'),
      infoWindow: const InfoWindow(title: 'Current Position'),
      position: const LatLng(0, 0),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );
    _markers.add(_currentPositionMarker);
    _positionStreamSubscription =
        Geolocator.getPositionStream().listen(_onPositionUpdate);
    // get position
    _getCurrentPosition();
    // fetch initial marker data
    fetchMarkerData();
    _kGooglePlex = CameraPosition(
      target: LatLng(widget.lat, widget.lng),
      zoom: 14,
    );
    followUser = widget.followUser;
    super.initState();
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    super.dispose();
  }

  void _onPositionUpdate(Position position) async {
    if (!mounted) return;
    final GoogleMapController controller = await _controller.future;
    if (followUser) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          ),
        ),
      );
    }
    final updatedMarker = Marker(
      markerId: _currentPositionMarker.markerId,
      infoWindow: _currentPositionMarker.infoWindow,
      position: LatLng(position.latitude, position.longitude),
      icon: _currentPositionMarker.icon,
      zIndex: 100.0,
    );

    setState(() {
      _markers.remove(_currentPositionMarker);
      _markers.add(updatedMarker);
      _currentPositionMarker = updatedMarker;
    });
  }

  // get current position
  Future<Position> _getCurrentPosition() async {
    final location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return location;

    setState(() {
      currentLocation = location;
    });
    return location;
  }

  void fetchMarkerData() async {
    final currentUserEmail = currentUser.email;

    // Fetch markers from the current user's collection
    final userMarkerSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserEmail)
        .collection('Markers')
        .get();

    final userMarkerDocs = userMarkerSnapshot.docs;

    // Process each document and add markers
    for (final doc in userMarkerDocs) {
      final data = doc.data();
      final name = data['name'] as String;
      final description = data['description'] as String;
      final location = data['location'] as Map<String, dynamic>;
      final latitude = location['latitude'] as double;
      final longitude = location['longitude'] as double;
      final type = data['type'] as String;
      final owner = data['markerOwner'];

      addMarker(
        name: name,
        description: description,
        location: LatLng(latitude, longitude),
        type: type,
        owner: owner,
      );
    }

    // Fetch friends' list
    final friendsSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserEmail)
        .get();

    final friendsData = friendsSnapshot.data();
    if (friendsData != null && friendsData.containsKey('friends')) {
      final friendsList = friendsData['friends'] as List<dynamic>;
      for (final friend in friendsList) {
        final friendMap = friend as Map<String, dynamic>;
        final friendEmail = friendMap['email'] as String;

        // Fetch markers from each friend's collection
        final friendMarkerSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(friendEmail)
            .collection('Markers')
            .get();

        final friendMarkerDocs = friendMarkerSnapshot.docs;

        // Process each friend's document and add markers
        for (final doc in friendMarkerDocs) {
          final data = doc.data();
          final name = data['name'] as String;
          final description = data['description'] as String;
          final location = data['location'] as Map<String, dynamic>;
          final latitude = location['latitude'] as double;
          final longitude = location['longitude'] as double;
          final type = data['type'] as String;
          final owner = data['markerOwner'];

          addMarker(
            name: name,
            description: description,
            location: LatLng(latitude, longitude),
            type: type,
            owner: owner,
          );
        }
      }
    } else {
      print('Error accessing friends docs');
    }

    // Subscribe to changes in the current user's collection for real-time updates
    FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserEmail)
        .collection('Markers')
        .snapshots()
        .listen((snapshot) {
      _markers.removeWhere(
          (marker) => marker.markerId.value.startsWith(currentUserEmail!));

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String;
        final description = data['description'] as String;
        final location = data['location'] as Map<String, dynamic>;
        final latitude = location['latitude'] as double;
        final longitude = location['longitude'] as double;
        final type = data['type'] as String;
        final owner = data['markerOwner'];

        addMarker(
          name: name,
          description: description,
          location: LatLng(latitude, longitude),
          type: type,
          owner: owner,
        );
      }
    });
  }

  // add markers
  Future<void> addMarker({
    required String name,
    required String description,
    required LatLng location,
    required String type,
    required String owner,
  }) async {
    final markerId = MarkerId(name);
    final marker = Marker(
      markerId: markerId,
      infoWindow: InfoWindow(
        title: name,
        snippet: '(tap here for more info)',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => ForageLocations(
                userId: currentUser.email!,
                userName: owner == currentUser.email
                    ? owner.split("@")[0]
                    : "Bookmarked Locations",
                userLocations: owner == currentUser.email,
              ),
            ),
          );
          AdMobService.showInterstitialAd();
        },
      ),
      position: location,
      icon: await getMarkerIcon(type),
    );

    // Create the corresponding circle
    final circle = Circle(
      circleId: CircleId('circle_$name'),
      center: location,
      radius: 200, // Adjust radius as needed
      fillColor: Colors.pinkAccent.withOpacity(0.3),
      strokeColor: Colors.pinkAccent,
      strokeWidth: 2,
    );

    if (!mounted) return;

    setState(() {
      _markers.add(marker);
      _circles.add(circle);
    });
  }

  Future<BitmapDescriptor> getMarkerIcon(String type) async {
    const double markerSize = 100.0; // Adjust to your desired size
    final ByteData byteData = await rootBundle
        .load('lib/assets/images/${type.toLowerCase()}_marker.png');
    final ui.Codec codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: markerSize.toInt(),
      targetHeight: markerSize.toInt(),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteDataBuffer =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List markerIcon = byteDataBuffer!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(markerIcon);
  }

  // get marker icon
  // Future<BitmapDescriptor> getMarkerIcon(String type) async {
  //   const double markerSize = 2.0;
  //   return BitmapDescriptor.fromAssetImage(
  //     const ImageConfiguration(size: Size(markerSize, markerSize)),
  //     'lib/assets/images/${type.toLowerCase()}_marker.png',
  //   );
  // }

  // go to place
  Future<void> _goToPlace(Map<String, dynamic> place) async {
    followUser = false;
    final double lat = place['geometry']['location']['lat'];
    final double lng = place['geometry']['location']['lng'];
    final GoogleMapController controller = await _controller.future;
    final newCameraPosition = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 14,
    );
    controller.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    // bool _followUser = followUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FORAGE'),
        titleTextStyle: GoogleFonts.philosopher(
            fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.5),
        centerTitle: true,
        backgroundColor: Colors.grey.shade600,
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: Column(
              children: [
                Text("Explore your local area for forageable ingredients."),
                Text('Mark the location so you can find it again!'),
              ],
            ),
          ),
          Expanded(
            // Container(
            child: GoogleMap(
              mapType: MapType.terrain,
              markers: _markers,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                controller.setMapStyle(mapstyle);
              },
              padding: const EdgeInsets.only(bottom: 60, left: 10),
              circles: _circles,
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 145.0,
            right: 18.0,
            child: FloatingActionButton(
              onPressed: () {
                setState(
                  () {
                    followUser = !followUser;
                  },
                );
              },
              shape: const RoundedRectangleBorder(),
              mini: true,
              backgroundColor: Colors.grey.shade800,
              child: Icon(
                Icons.my_location,
                color: followUser ? Colors.deepOrange.shade300 : Colors.white,
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: 20,
            right: -100,
            child: Container(
              margin: const EdgeInsets.only(right: 150),
              child: Row(
                children: [
                  Expanded(
                    child: SearchField(
                      onPlaceSelected: _goToPlace,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // this line prevents compass cutoff
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
    );
  }
}
