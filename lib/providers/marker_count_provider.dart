import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final markerCountProvider = StateNotifierProvider<MarkerCountNotifier, int>(
  (ref) => MarkerCountNotifier(),
);

// Provider for counting markers where the owner is not the current user
final nonOwnerMarkerCountProvider = StateNotifierProvider<NonOwnerMarkerCountNotifier, int>(
  (ref) => NonOwnerMarkerCountNotifier(),
);

class MarkerCountNotifier extends StateNotifier<int> {
  MarkerCountNotifier() : super(0);

  void updateMarkerCount(String userId, bool isOwner) {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Markers')
        .where('markerOwner', isEqualTo: isOwner ? userId : null)
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.length;
    });
  }
}

class NonOwnerMarkerCountNotifier extends StateNotifier<int> {
  NonOwnerMarkerCountNotifier() : super(0);

  void updateNonOwnerMarkerCount(String userId) {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Markers')
        .where('markerOwner', isNotEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.length;
    });
  }
}
