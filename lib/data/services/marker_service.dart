import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
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

  // UPDATED: Use root Markers collection
  Future<MarkerModel> getMarkerById(String markerId, String ownerEmail) async {
    final doc = await _firestore
        .collection('Markers')
        .doc(markerId)
        .get();

    return MarkerModel.fromFirestore(doc);
  }

  // UPDATED: Use root Markers collection
  Stream<MarkerModel> getMarkerStream(String markerId, String ownerEmail) {
    return _firestore
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

      // UPDATED: Save to root Markers collection instead of subcollection
      await _firestore
          .collection('Markers')  // Changed from Users/{email}/Markers
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
        'userId': user.email,  // Added for consistency with migration
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
    if (images.isEmpty) return [];

    try {
      // Upload all images in parallel for better performance
      final uploadFutures = images.asMap().entries.map((entry) async {
        final index = entry.key;
        final image = entry.value;
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
        final storageRef = _storage.ref().child('marker_images/$fileName');
        await storageRef.putFile(image);
        return await storageRef.getDownloadURL();
      });

      return await Future.wait(uploadFutures);
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
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
    required String markerId, // We'll ignore this too
    required String newStatus,
    required String notes,
    required String markerOwnerEmail,
    String? markerName,
    String? markerType,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;

      // Get username
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .get();

      final username =
          userDoc.exists ? userDoc['username'] ?? 'Anonymous' : 'Anonymous';

      final statusUpdate = {
        'status': newStatus,
        'userId': currentUser.uid,
        'userEmail': currentUser.email!,
        'username': username,
        'timestamp': Timestamp.now(),
        if (notes.isNotEmpty) 'notes': notes,
      };

      // UPDATED: Use root Markers collection
      final markersCollection = FirebaseFirestore.instance
          .collection('Markers');

      if (markerName != null && markerType != null) {
        final querySnapshot = await markersCollection
            .where('markerOwner', isEqualTo: markerOwnerEmail)
            .where('name', isEqualTo: markerName)
            .where('type', isEqualTo: markerType)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw Exception(
              'No marker found with name: $markerName and type: $markerType');
        }

        for (final doc in querySnapshot.docs) {
          await doc.reference.update({
            'currentStatus': newStatus,
            'statusHistory': FieldValue.arrayUnion([statusUpdate])
          });
        }
      } else {
        throw Exception('Marker name and type are required to update status');
      }
    } catch (e) {
      print('Error updating marker status: $e');
      rethrow;
    }
  }

  Future<void> addComment({
    required String markerId, // We'll ignore this and find the correct one
    required String text,
    required String markerOwnerEmail,
    String? markerName,
    String? markerType,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;

      // Get the current user's username and profile pic
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .get();

      final username =
          userDoc.exists ? userDoc['username'] ?? 'Anonymous' : 'Anonymous';
      final profilePic = userDoc.exists ? userDoc['profilePic'] ?? '' : '';

      final comment = {
        'userId': currentUser.uid,
        'userEmail': currentUser.email!,
        'username': username,
        'profilePic': profilePic, // Add profile pic to comment
        'text': text,
        'timestamp': Timestamp.now(),
      };

      // UPDATED: Use root Markers collection
      final markersCollection = FirebaseFirestore.instance
          .collection('Markers');

      // Always use query-based approach to find the correct document
      if (markerName != null && markerType != null) {
        final querySnapshot = await markersCollection
            .where('markerOwner', isEqualTo: markerOwnerEmail)
            .where('name', isEqualTo: markerName)
            .where('type', isEqualTo: markerType)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw Exception(
              'No marker found with name: $markerName and type: $markerType');
        }

        // Update all matching documents (should typically be just one)
        for (final doc in querySnapshot.docs) {
          print('Adding comment to document ID: ${doc.id}');
          await doc.reference.update({
            'comments': FieldValue.arrayUnion([comment])
          });
        }
      } else {
        throw Exception('Marker name and type are required to add comments');
      }
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }
}
