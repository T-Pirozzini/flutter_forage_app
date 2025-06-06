import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final markerServiceProvider = Provider<MarkerService>((ref) {
  return MarkerService(FirebaseAuth.instance.currentUser!);
});

class MarkerService {
  final User _user;

  MarkerService(this._user);

  Stream<QuerySnapshot> getMarkersStream() {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(_user.email)
        .collection('Markers')
        .snapshots();
  }

  Future<Marker> createMarkerFromDoc(
      DocumentSnapshot doc, String ownerEmail) async {
    final data = doc.data() as Map<String, dynamic>;
    final location = data['location'] as Map<String, dynamic>;
    final latLng = LatLng(
      (location['latitude'] as num).toDouble(),
      (location['longitude'] as num).toDouble(),
    );

    return Marker(
      markerId: MarkerId(doc.id),
      position: latLng,
      icon: await _getMarkerIcon(data['type'] ?? 'plant'),
      infoWindow: InfoWindow(
        title: data['name'] ?? 'Unnamed Location',
        snippet: '(tap for details)',
      ),
    );
  }

  Future<void> saveMarker({
    required String name,
    required String description,
    required String type,
    required Position position,
    List<String> images = const [], // Optional for now
  }) async {
    final markerData = {
      'name': name,
      'description': description,
      'type': type,
      'images': images,
      'location': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(_user.email)
        .collection('Markers')
        .add(markerData);
  }

  Future<BitmapDescriptor> _getMarkerIcon(String type) async {
    const double markerSize = 100.0;
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
}
