import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String bio;
  final String profilePic;
  final String profileBackground;
  final List<String> friends;
  final Map<String, String> friendRequests;
  final List<String> savedRecipes;
  final List<String> savedLocations;
  final Map<String, int> forageStats;
  final Map<String, dynamic> preferences;
  final Timestamp createdAt;
  final Timestamp lastActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.bio = "",
    this.profilePic = 'profileImage1.jpg',
    this.profileBackground = 'backgroundProfileImage1.jpg',
    this.friends = const [],
    this.friendRequests = const {},
    this.savedRecipes = const [],
    this.savedLocations = const [],
    this.forageStats = const {},
    this.preferences = const {},
    required this.createdAt,
    required this.lastActive,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      bio: data['bio'] ?? '',
      profilePic: data['profilePic'] ?? 'profileImage1.jpg',
      profileBackground:
          data['profileBackground'] ?? 'backgroundProfileImage1.jpg',
      friends: List<String>.from(data['friends'] ?? []),
      friendRequests: Map<String, String>.from(data['friendRequests'] ?? {}),
      savedRecipes: List<String>.from(data['savedRecipes'] ?? []),
      savedLocations: List<String>.from(data['savedLocations'] ?? []),
      forageStats: Map<String, int>.from(data['forageStats'] ?? {}),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastActive: data['lastActive'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'bio': bio,
      'profilePic': profilePic,
      'profileBackground': profileBackground,
      'friends': friends,
      'friendRequests': friendRequests,
      'savedRecipes': savedRecipes,
      'savedLocations': savedLocations,
      'forageStats': forageStats,
      'preferences': preferences,
      'createdAt': createdAt,
      'lastActive': lastActive,
    };
  }

  // Helper methods
  bool hasPendingRequestFrom(String userId) =>
      friendRequests[userId] == 'pending';

  List<String> get pendingIncomingRequests => friendRequests.entries
      .where((e) => e.value == 'pending')
      .map((e) => e.key)
      .toList();
}

enum FriendRequestStatus { pending, accepted, rejected, cancelled }
