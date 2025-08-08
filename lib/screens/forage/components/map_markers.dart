import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapMarkerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final User currentUser;

  MapMarkerService(this.currentUser);

  Future<void> saveMarker({
    required String name,
    required String description,
    required String type,
    required List<File> images,
    required Position position,
  }) async {
    try {
      final imageUrls = await _uploadImages(images);
      final userDoc =
          await _firestore.collection('Users').doc(currentUser.email).get();
      final username = userDoc.data()?['username'] ?? 'Anonymous';

      await _firestore
          .collection('Users')
          .doc(currentUser.email)
          .collection('Markers')
          .add({
        'name': name,
        'description': description,
        'type': type,
        'images': imageUrls, // Store all images instead of just first
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'timestamp': Timestamp.now(),
        'markerOwner': currentUser.email,
        'currentStatus': 'active', // New field
        'statusHistory': [
          // New field
          {
            'status': 'active',
            'userId': currentUser.uid,
            'userEmail': currentUser.email,
            'username': username,
            'timestamp': Timestamp.now(),
            'notes': 'Marker created',
          }
        ],
      });
    } catch (e) {
      throw Exception('Failed to save marker: $e');
    }
  }

  Future<List<String>> _uploadImages(List<File> images) async {
    final List<String> imageUrls = [];

    await Future.wait(images.map((image) async {
      try {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${images.indexOf(image)}.jpg';
        final storageRef = _storage.ref().child('marker_images/$fileName');
        await storageRef.putFile(image);
        final downloadUrl = await storageRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      } catch (e) {
        throw Exception('Failed to upload image: $e');
      }
    }));

    return imageUrls;
  }

  Future<void> updateMarkerStatus({
    required String markerId,
    required String newStatus,
    String? notes,
    required String markerOwnerEmail,
  }) async {
    final userDoc =
        await _firestore.collection('Users').doc(currentUser.email).get();
    final username = userDoc.data()?['username'] ?? 'Anonymous';

    final update = {
      'status': newStatus,
      'userId': currentUser.uid,
      'userEmail': currentUser.email,
      'username': username,
      'timestamp': FieldValue.serverTimestamp(),
      if (notes != null) 'notes': notes,
    };

    await _firestore
        .collection('Users')
        .doc(markerOwnerEmail)
        .collection('Markers')
        .doc(markerId)
        .update({
      'currentStatus': newStatus,
      'statusHistory': FieldValue.arrayUnion([update]),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<BitmapDescriptor> getMarkerIcon(String type) async {
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
