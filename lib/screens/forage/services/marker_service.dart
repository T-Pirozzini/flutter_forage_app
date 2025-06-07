import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_forager_app/models/marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final markerServiceProvider = Provider<MarkerService>((ref) {
  return MarkerService(FirebaseAuth.instance.currentUser!);
});

class MarkerService {
  final User user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  MarkerService(this.user);

  Future<MarkerModel> getMarkerById(String markerId, String ownerEmail) async {
    final doc = await _firestore
        .collection('Users')
        .doc(ownerEmail)
        .collection('Markers')
        .doc(markerId)
        .get();

    return MarkerModel.fromFirestore(doc);
  }

  Stream<MarkerModel> getMarkerStream(String markerId, String ownerEmail) {
    return _firestore
        .collection('Users')
        .doc(ownerEmail)
        .collection('Markers')
        .doc(markerId)
        .snapshots()
        .map((doc) => MarkerModel.fromFirestore(doc));
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
    required List<File> images,
    required Position position,
  }) async {
    try {
      final imageUrls = await _uploadImages(images);
      final userDoc =
          await _firestore.collection('Users').doc(user.email).get();
      final username = userDoc.data()?['username'] ?? 'Anonymous';

      await _firestore
          .collection('Users')
          .doc(user.email)
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
        'markerOwner': user.email,
        'currentStatus': 'active',
        'statusHistory': [
          {
            'status': 'active',
            'userId': user.uid,
            'userEmail': user.email,
            'username': username,
            'timestamp': FieldValue.serverTimestamp(),
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

    for (final image in images) {
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
    }

    return imageUrls;
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

  Future<void> updateMarkerStatus({
    required String markerId,
    required String newStatus,
    String? notes,
    required String markerOwnerEmail,
  }) async {
    final userDoc = await _firestore.collection('Users').doc(user.email).get();
    final username = userDoc.data()?['username'] ?? 'Anonymous';
    final now = DateTime.now(); // Use local timestamp

    await _firestore
        .collection('Users')
        .doc(markerOwnerEmail)
        .collection('Markers')
        .doc(markerId)
        .update({
      'currentStatus': newStatus,
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': newStatus,
          'userId': user.uid,
          'userEmail': user.email,
          'username': username,
          'timestamp':
              Timestamp.fromDate(now), // Convert to Firestore Timestamp
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }
      ]),
    });
  }

  Future<void> addComment({
    required String markerId,
    required String text,
    required String markerOwnerEmail,
  }) async {
    final userDoc = await _firestore.collection('Users').doc(user.email).get();
    final username = userDoc.data()?['username'] ?? 'Anonymous';
    final now = DateTime.now(); // Use local timestamp

    await _firestore
        .collection('Users')
        .doc(markerOwnerEmail)
        .collection('Markers')
        .doc(markerId)
        .update({
      'comments': FieldValue.arrayUnion([
        {
          'userId': user.uid,
          'userEmail': user.email,
          'username': username,
          'text': text,
          'timestamp':
              Timestamp.fromDate(now), // Convert to Firestore Timestamp
        }
      ])
    });
  }
}
