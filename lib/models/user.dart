import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String email;
  final String username;
  final String bio;
  final String profilePic;
  final String profileBackground;
  final List<dynamic> friends;
  final List<dynamic> friendRequests;
  final List<dynamic> sentFriendRequests;
  final List<dynamic> posts;
  final List<String> badges;
  final int streak;
  final int totalForages;
  final Map<String, dynamic> preferences;
  final Timestamp createdAt;

  UserModel({
    required this.email,
    required this.username,
    required this.bio,
    required this.profilePic,
    required this.profileBackground,
    required this.friends,
    required this.friendRequests,
    required this.sentFriendRequests,
    required this.posts,
    required this.badges,
    required this.streak,
    required this.totalForages,
    required this.preferences,
    required this.createdAt,
  });

  // Factory constructor for Firestore data
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      bio: data['bio'] ?? '',
      profilePic: data['profilePic'] ?? 'profileImage1.jpg',
      profileBackground:
          data['profileBackground'] ?? 'backgroundProfileImage1.jpg',
      friends: data['friends'] ?? [],
      friendRequests: data['friendRequests'] ?? [],
      sentFriendRequests: data['sentFriendRequests'] ?? [],
      posts: data['posts'] ?? [],
      badges: List<String>.from(data['badges'] ?? []),
      streak: data['streak'] ?? 0,
      totalForages: data['totalForages'] ?? 0,
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
