import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final mapServiceProvider = Provider<MapService>((ref) {
  return MapService(FirebaseAuth.instance.currentUser!);
});

class MapService {
  final User _user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MapService(this._user);

  Stream<QuerySnapshot> getUserMarkersStream() {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(_user.email)
        .collection('Markers')
        .snapshots();
  }

  Stream<DocumentSnapshot> getUserFriendsStream() {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(_user.email)
        .snapshots();
  }

  Future<void> saveMarker({
    required String name,
    required String description,
    required String type,
    required List<File> images,
    required Position position,
  }) async {
    final userDoc = await _firestore.collection('Users').doc(_user.email).get();
    final username = userDoc.data()?['username'] ?? 'Anonymous';

    final markerData = {
      'name': name,
      'description': description,
      'type': type,
      'location': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'timestamp': FieldValue.serverTimestamp(),
      'markerOwner': _user.email,
      'currentStatus': 'active',
      'statusHistory': [
        {
          'status': 'active',
          'userId': _user.uid,
          'userEmail': _user.email,
          'username': username,
          'timestamp': FieldValue.serverTimestamp(),
          'notes': 'Marker created',
        }
      ],
    };

    await _firestore
        .collection('Users')
        .doc(_user.email)
        .collection('Markers')
        .add(markerData);
  }

}