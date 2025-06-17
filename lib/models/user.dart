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
  final Map<String, String> sentFriendRequests;
  final List<String> savedRecipes;
  final List<String> savedLocations;
  final Map<String, int> forageStats;
  final Map<String, dynamic> preferences;
  final Timestamp createdAt;
  final Timestamp lastActive;
  final bool isFriend;
  final bool hasPendingRequest;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.bio = "",
    this.profilePic = 'profileImage1.jpg',
    this.profileBackground = 'backgroundProfileImage1.jpg',
    this.friends = const [],
    this.friendRequests = const {},
    this.sentFriendRequests = const {},
    this.savedRecipes = const [],
    this.savedLocations = const [],
    this.forageStats = const {},
    this.preferences = const {},
    required this.createdAt,
    required this.lastActive,
    this.isFriend = false,
    this.hasPendingRequest = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  // Helper function to safely convert dynamic to Map<String, String>
  Map<String, String> safeStringMapConvert(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return Map<String, String>.from(value);
    }
    return {};
  }

  // Helper function to safely convert dynamic to Map<String, int>
  Map<String, int> safeIntMapConvert(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return Map<String, int>.from(value);
    }
    return {};
  }

  // Helper function to safely convert dynamic to List<String>
  List<String> safeStringListConvert(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return List<String>.from(value.whereType<String>());
    }
    return [];
  }

  // Helper function to get string value with fallback for empty strings
  String getStringValue(dynamic value, String fallback) {
    if (value == null) return fallback;
    final stringValue = value.toString().trim();
    return stringValue.isNotEmpty ? stringValue : fallback;
  }

  return UserModel(
    uid: doc.id,
    email: data['email']?.toString() ?? '',
    username: data['username']?.toString() ?? '',
    bio: data['bio']?.toString() ?? '',
    profilePic: getStringValue(data['profilePic'], 'profileImage1.jpg'),
    profileBackground: getStringValue(data['profileBackground'], 'backgroundProfileImage1.jpg'),
    friends: safeStringListConvert(data['friends']),
    friendRequests: safeStringMapConvert(data['friendRequests']),
    sentFriendRequests: safeStringMapConvert(data['sentFriendRequests']),
    savedRecipes: safeStringListConvert(data['savedRecipes']),
    savedLocations: safeStringListConvert(data['savedLocations']),
    forageStats: safeIntMapConvert(data['forageStats']),
    preferences: data['preferences'] is Map
        ? Map<String, dynamic>.from(data['preferences'])
        : {},
    createdAt: data['createdAt'] is Timestamp
        ? data['createdAt'] as Timestamp
        : Timestamp.now(),
    lastActive: data['lastActive'] is Timestamp
        ? data['lastActive'] as Timestamp
        : Timestamp.now(),
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
      'sentFriendRequests': sentFriendRequests,
      'savedRecipes': savedRecipes,
      'savedLocations': savedLocations,
      'forageStats': forageStats,
      'preferences': preferences,
      'createdAt': createdAt,
      'lastActive': lastActive,
    };
  }

  bool hasPendingRequestFrom(String userId) =>
      friendRequests.containsKey(userId) && friendRequests[userId] == 'pending';

  bool hasPendingSentRequestTo(String userId) =>
      sentFriendRequests.containsKey(userId) &&
      sentFriendRequests[userId] == 'pending';

  List<String> get pendingIncomingRequests => friendRequests.entries
      .where((e) => e.value == 'pending')
      .map((e) => e.key)
      .toList();

  List<String> get pendingSentRequests => sentFriendRequests.entries
      .where((e) => e.value == 'pending')
      .map((e) => e.key)
      .toList();

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? bio,
    String? profilePic,
    String? profileBackground,
    List<String>? friends,
    Map<String, String>? friendRequests,
    Map<String, String>? sentFriendRequests,
    List<String>? savedRecipes,
    List<String>? savedLocations,
    Map<String, int>? forageStats,
    Map<String, dynamic>? preferences,
    Timestamp? createdAt,
    Timestamp? lastActive,
    bool? isFriend,
    bool? hasPendingRequest,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profilePic: profilePic ?? this.profilePic,
      profileBackground: profileBackground ?? this.profileBackground,
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      sentFriendRequests: sentFriendRequests ?? this.sentFriendRequests,
      savedRecipes: savedRecipes ?? this.savedRecipes,
      savedLocations: savedLocations ?? this.savedLocations,
      forageStats: forageStats ?? this.forageStats,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isFriend: isFriend ?? this.isFriend,
      hasPendingRequest: hasPendingRequest ?? this.hasPendingRequest,
    );
  }
}

enum FriendRequestStatus { pending, accepted, rejected, cancelled }
