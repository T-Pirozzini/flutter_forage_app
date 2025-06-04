import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsService {
  final FirebaseFirestore _firestore;

  FriendsService() : _firestore = FirebaseFirestore.instance;

  Future<void> sendFriendRequest(String senderId, String recipientId) async {
    await _firestore.collection('Users').doc(recipientId).update({
      'friendRequests.$senderId': 'pending',
    });
  }

  Future<void> acceptFriendRequest(String acceptorId, String requesterId) async {
    final batch = _firestore.batch();
    
    batch.update(_firestore.collection('Users').doc(acceptorId), {
      'friends': FieldValue.arrayUnion([requesterId]),
      'friendRequests.$requesterId': 'accepted',
    });
    
    batch.update(_firestore.collection('Users').doc(requesterId), {
      'friends': FieldValue.arrayUnion([acceptorId]),
      'friendRequests.$acceptorId': 'accepted',
    });
    
    await batch.commit();
  }

  Future<void> rejectFriendRequest(String userId, String requesterId) async {
    await _firestore.collection('Users').doc(userId).update({
      'friendRequests.$requesterId': 'rejected',
    });
  }

  Future<void> removeFriend(String userId, String friendId) async {
    final batch = _firestore.batch();
    
    batch.update(_firestore.collection('Users').doc(userId), {
      'friends': FieldValue.arrayRemove([friendId]),
    });
    
    batch.update(_firestore.collection('Users').doc(friendId), {
      'friends': FieldValue.arrayRemove([userId]),
    });
    
    await batch.commit();
  }
}