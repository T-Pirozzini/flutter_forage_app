import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendFriendRequest(String senderId, String recipientId) async {
    final batch = _firestore.batch();
    
    // Add to recipient's requests
    batch.update(
      _firestore.collection('Users').doc(recipientId),
      {
        'friendRequests.$senderId': 'pending',
      },
    );
    
    // Add to sender's sent requests (optional - you may need to add this field)
    batch.update(
      _firestore.collection('Users').doc(senderId),
      {
        'sentFriendRequests.$recipientId': 'pending',
      },
    );
    
    await batch.commit();
  }

  Future<void> acceptFriendRequest(String acceptorId, String requesterId) async {
    final batch = _firestore.batch();
    final timestamp = Timestamp.now();
    
    // Update request status
    batch.update(
      _firestore.collection('Users').doc(acceptorId),
      {
        'friendRequests.$requesterId': 'accepted',
      },
    );
    
    // Add to both friends lists
    batch.update(
      _firestore.collection('Users').doc(acceptorId),
      {
        'friends': FieldValue.arrayUnion([requesterId]),
      },
    );
    
    batch.update(
      _firestore.collection('Users').doc(requesterId),
      {
        'friends': FieldValue.arrayUnion([acceptorId]),
        'sentFriendRequests.$acceptorId': 'accepted',
      },
    );
    
    await batch.commit();
  }

  Future<void> rejectFriendRequest(String userId, String requesterId) async {
    await _firestore.collection('Users').doc(userId).update({
      'friendRequests.$requesterId': 'rejected',
    });
    
    // Also update sender's sent requests if you're tracking them
    await _firestore.collection('Users').doc(requesterId).update({
      'sentFriendRequests.$userId': 'rejected',
    });
  }

  Future<void> removeFriend(String userId, String friendId) async {
    final batch = _firestore.batch();
    
    batch.update(
      _firestore.collection('Users').doc(userId),
      {
        'friends': FieldValue.arrayRemove([friendId]),
      },
    );
    
    batch.update(
      _firestore.collection('Users').doc(friendId),
      {
        'friends': FieldValue.arrayRemove([userId]),
      },
    );
    
    await batch.commit();
  }
}