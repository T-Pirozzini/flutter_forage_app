import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final markerCountProvider = StateNotifierProvider.family<MarkerCountNotifier, int, String>(
  (ref, userId) => MarkerCountNotifier(userId),
);

final nonOwnerMarkerCountProvider = StateNotifierProvider.family<NonOwnerMarkerCountNotifier, int, String>(
  (ref, userId) => NonOwnerMarkerCountNotifier(userId),
);

class MarkerCountNotifier extends StateNotifier<int> {
  final String userId;
  MarkerCountNotifier(this.userId) : super(0) {
    _init();
  }

  void _init() {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Markers')
        .where('markerOwner', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) => state = snapshot.docs.length);
  }
}

class NonOwnerMarkerCountNotifier extends StateNotifier<int> {
  final String userId;
  NonOwnerMarkerCountNotifier(this.userId) : super(0) {
    _init();
  }

  void _init() {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Markers')
        .where('markerOwner', isNotEqualTo: userId)
        .snapshots()
        .listen((snapshot) => state = snapshot.docs.length);
  }
}