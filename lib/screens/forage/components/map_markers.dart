import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

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
      
      await _firestore
          .collection('Users')
          .doc(currentUser.email)
          .collection('Markers')
          .add({
        'name': name,
        'description': description,
        'type': type,
        'image': imageUrls.isNotEmpty ? imageUrls.first : null,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'timestamp': FieldValue.serverTimestamp(),
        'markerOwner': currentUser.email,
      });
    } catch (e) {
      throw Exception('Failed to save marker: $e');
    }
  }

  Future<List<String>> _uploadImages(List<File> images) async {
    final List<String> imageUrls = [];
    
    await Future.wait(images.map((image) async {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${images.indexOf(image)}.jpg';
      final storageRef = _storage.ref().child('images/$fileName');
      await storageRef.putFile(image);
      final downloadUrl = await storageRef.getDownloadURL();
      imageUrls.add(downloadUrl);
    }));
    
    return imageUrls;
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