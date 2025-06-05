import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/models/marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userMarkersProvider = StreamProvider.family<List<MarkerModel>, String>(
  (ref, userId) {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Markers')
        .where('markerOwner', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MarkerModel.fromFirestore(doc))
            .toList());
  },
);

final communityMarkersProvider = StreamProvider.family<List<MarkerModel>, String>(
  (ref, userId) {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Markers')
        .where('markerOwner', isNotEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MarkerModel.fromFirestore(doc))
            .toList());
  },
);