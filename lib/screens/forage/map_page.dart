import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forager_app/components/ad_mob_service.dart';
import 'package:flutter_forager_app/components/screen_heading.dart';
import 'package:flutter_forager_app/screens/forage/map_style.dart';
import 'package:flutter_forager_app/screens/forage/marker_buttons.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_location_info_page.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_locations_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
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

    // Clear existing markers (keeping only the current position marker)
    setState(() {
      _markers.removeWhere(
          (marker) => marker.markerId != const MarkerId('currentPosition'));
    });

    // Set up real-time listener for user's markers first
    FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserEmail)
        .collection('Markers')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      // Clear only user's markers (keeping current position and friends' markers)
      _markers.removeWhere((marker) =>
          marker.markerId.value.startsWith('${currentUserEmail}_') &&
          marker.markerId != const MarkerId('currentPosition'));

      // Add/update user's markers
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'] as Map<String, dynamic>;
        addMarker(
          name: data['name'] ?? 'Unnamed Location',
          description: data['description'] ?? '',
          location: LatLng(
            (location['latitude'] as num).toDouble(),
            (location['longitude'] as num).toDouble(),
          ),
          type: data['type'] ?? 'plant',
          owner: data['markerOwner'] ?? currentUserEmail!,
          imageUrls: (data['images'] as List<dynamic>?)?.cast<String>() ?? [],
        );
      }
    });

    // Initial load of user's markers
    final userMarkerSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserEmail)
        .collection('Markers')
        .get();

    for (final doc in userMarkerSnapshot.docs) {
      final data = doc.data();
      final location = data['location'] as Map<String, dynamic>;
      await addMarker(
        name: data['name'] ?? 'Unnamed Location',
        description: data['description'] ?? '',
        location: LatLng(
          (location['latitude'] as num).toDouble(),
          (location['longitude'] as num).toDouble(),
        ),
        type: data['type'] ?? 'plant',
        owner: data['markerOwner'] ?? currentUserEmail!,
        imageUrls: (data['images'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    }

    // Load friends' markers
    final friendsSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserEmail)
        .get();

    final friendsData = friendsSnapshot.data();
    if (friendsData != null && friendsData.containsKey('friends')) {
      final friendsList = friendsData['friends'] as List<dynamic>;

      // Process friends in parallel
      await Future.wait(friendsList.map((friend) async {
        try {
          final friendEmail =
              (friend as Map<String, dynamic>)['email'] as String;
          final friendMarkerSnapshot = await FirebaseFirestore.instance
              .collection('Users')
              .doc(friendEmail)
              .collection('Markers')
              .get();

          for (final doc in friendMarkerSnapshot.docs) {
            final data = doc.data();
            final location = data['location'] as Map<String, dynamic>;
            await addMarker(
              name: data['name'] ?? 'Unnamed Location',
              description: data['description'] ?? '',
              location: LatLng(
                (location['latitude'] as num).toDouble(),
                (location['longitude'] as num).toDouble(),
              ),
              type: data['type'] ?? 'plant',
              owner: data['markerOwner'] ?? friendEmail,
              imageUrls:
                  (data['images'] as List<dynamic>?)?.cast<String>() ?? [],
            );
          }
        } catch (e) {
          debugPrint('Error loading friend markers: $e');
        }
      }));
    }
  }

  // add markers
  Future<void> addMarker({
    required String name,
    required String description,
    required LatLng location,
    required String type,
    required String owner,
    List<String>? imageUrls,
  }) async {
    final markerId = MarkerId('${owner}_${name}_${location.latitude}');
    final marker = Marker(
      markerId: markerId,
      infoWindow: InfoWindow(
        title: name,
        snippet: '(tap here for more info)',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForageLocationInfo(
                name: name,
                description: description,
                lat: location.latitude,
                lng: location.longitude,
                timestamp: DateTime.now().toString(),
                type: type,
                markerOwner: owner,
                imageUrls:
                    imageUrls ?? [], // You'll need to fetch this from Firestore
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

  void _showMarkerTypeSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Marker Type', style: TextStyle(fontSize: 20)),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMarkerTypeButton(
                    context, 'Plant', 'lib/assets/images/plant.png'),
                _buildMarkerTypeButton(
                    context, 'Berries', 'lib/assets/images/berries.png'),
                _buildMarkerTypeButton(
                    context, 'Mushroom', 'lib/assets/images/mushroom.png'),
                _buildMarkerTypeButton(
                    context, 'Tree', 'lib/assets/images/tree.png'),
                _buildMarkerTypeButton(
                    context, 'Fish', 'lib/assets/images/fish.png'),
                _buildMarkerTypeButton(
                    context, 'Shellfish', 'lib/assets/images/shellfish.png'),
                _buildMarkerTypeButton(
                    context, 'Nuts', 'lib/assets/images/nuts.png'),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddMarkerDialog(String markerType) async {
    final position = await _getCurrentPosition();
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    List<File> selectedImages = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add $markerType Location'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Location Name'),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: descController,
                    decoration: InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  if (selectedImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Image.file(selectedImages[index], height: 100),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () => setState(() {
                                    selectedImages.removeAt(index);
                                  }),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      final images = await ImagePicker().pickMultiImage();
                      if (images != null && images.isNotEmpty) {
                        setState(() {
                          selectedImages
                              .addAll(images.map((x) => File(x.path)));
                        });
                      }
                    },
                    child: Text('Add Images (${selectedImages.length}/3)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _saveMarker(
                    nameController.text,
                    descController.text,
                    markerType,
                    selectedImages, // Pass all images
                    position,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMarker(
    String name,
    String description,
    String type,
    List<File> images,
    Position position,
  ) async {
    try {
      List<String> imageUrls = [];

      // Upload all images in parallel
      await Future.wait(images.map((image) async {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${images.indexOf(image)}.jpg';
        final storageRef =
            FirebaseStorage.instance.ref().child('images/$fileName');
        await storageRef.putFile(image);
        final downloadUrl = await storageRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      }));

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .collection('Markers')
          .add({
        'name': name,
        'description': description,
        'type': type,
        'images': imageUrls,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'timestamp': FieldValue.serverTimestamp(),
        'markerOwner': currentUser.email,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving location: $e')),
      );
    }
  }

  Widget _buildMarkerTypeButton(
      BuildContext context, String type, String imagePath) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close the bottom sheet
        _showAddMarkerDialog(type);
      },
      child: Column(
        children: [
          Image.asset(imagePath, width: 50, height: 50),
          SizedBox(height: 4),
          Text(type),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // bool _followUser = followUser;

    return Scaffold(
      body: Column(
        children: [
          ScreenHeading(title: 'Forage'),
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
              heroTag: 'locationButton',
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
          Positioned(
            bottom: 80.0,
            left: 18.0,
            child: FloatingActionButton(
              heroTag: 'add_marker_fab',
              onPressed: () => _showMarkerTypeSelection(context),
              backgroundColor: Colors.deepOrange.shade300,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
      // this line prevents compass cutoff
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
    );
  }
}
