/// Firestore collection name constants
///
/// Centralizes all collection names to prevent typos and make refactoring easier.
class FirestoreCollections {
  // Prevent instantiation
  FirestoreCollections._();

  // Root collections
  static const String users = 'Users';
  static const String markers = 'Markers'; // NEW - migrating from subcollection
  static const String posts = 'Posts';
  static const String recipes = 'Recipes';
  static const String feedback = 'Feedback';
  static const String communityMessages = 'CommunityMessages';

  // Legacy subcollection path (will be deprecated after migration)
  @Deprecated('Use markers root collection instead')
  static String userMarkersSubcollection(String userId) => 'Users/$userId/Markers';
}

/// Firestore field name constants
class FirestoreFields {
  FirestoreFields._();

  // Common fields
  static const String id = 'id';
  static const String timestamp = 'timestamp';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';

  // User fields
  static const String uid = 'uid';
  static const String email = 'email';
  static const String username = 'username';
  static const String points = 'points';
  static const String level = 'level';
  static const String achievements = 'achievements';

  // Marker fields
  static const String userId = 'userId'; // Owner of the marker
  static const String markerOwner = 'markerOwner'; // Legacy field
  static const String name = 'name';
  static const String description = 'description';
  static const String type = 'type';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String status = 'status';
  static const String currentStatus = 'currentStatus';

  // Social fields
  static const String likes = 'likes';
  static const String likedBy = 'likedBy';
  static const String likeCount = 'likeCount';
  static const String bookmarkedBy = 'bookmarkedBy';
  static const String bookmarkCount = 'bookmarkCount';
  static const String comments = 'comments';
  static const String commentCount = 'commentCount';
}
