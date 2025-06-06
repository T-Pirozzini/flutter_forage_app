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
    // Implement your marker saving logic
    // This should include image upload if needed
  }
}