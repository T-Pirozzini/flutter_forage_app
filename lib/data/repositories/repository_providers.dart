import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/data/repositories/activity_feed_repository.dart';
import 'package:flutter_forager_app/data/repositories/bookmark_repository.dart';
import 'package:flutter_forager_app/data/repositories/collection_repository.dart';
import 'package:flutter_forager_app/data/repositories/custom_marker_type_repository.dart';
import 'package:flutter_forager_app/data/repositories/direct_message_repository.dart';
import 'package:flutter_forager_app/data/repositories/following_repository.dart';
import 'package:flutter_forager_app/data/repositories/roadmap_repository.dart';
import 'package:flutter_forager_app/data/repositories/emergency_notification_repository.dart';
import 'package:flutter_forager_app/data/repositories/forage_request_repository.dart';
import 'package:flutter_forager_app/data/repositories/friend_repository.dart';
import 'package:flutter_forager_app/data/repositories/marker_repository.dart';
import 'package:flutter_forager_app/data/repositories/post_draft_repository.dart';
import 'package:flutter_forager_app/data/repositories/post_repository.dart';
import 'package:flutter_forager_app/data/repositories/recipe_repository.dart';
import 'package:flutter_forager_app/data/repositories/saved_recipe_repository.dart';
import 'package:flutter_forager_app/data/repositories/user_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';
import 'package:flutter_forager_app/data/services/notification_service.dart';
import 'package:flutter_forager_app/data/services/post_migration_service.dart';

/// Providers for repositories
///
/// These providers make repositories available throughout the app via Riverpod.
/// Use these providers in your widgets and other providers to access data.

/// FirestoreService provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// MarkerRepository provider
final markerRepositoryProvider = Provider<MarkerRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return MarkerRepository(firestoreService: firestoreService);
});

/// UserRepository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return UserRepository(firestoreService: firestoreService);
});

/// PostRepository provider
final postRepositoryProvider = Provider<PostRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PostRepository(firestoreService: firestoreService);
});

/// RecipeRepository provider
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return RecipeRepository(firestoreService: firestoreService);
});

/// CustomMarkerTypeRepository provider
final customMarkerTypeRepositoryProvider = Provider<CustomMarkerTypeRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return CustomMarkerTypeRepository(firestoreService: firestoreService);
});

/// FriendRepository provider
///
/// Manages friend relationships and friend requests using subcollections.
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FriendRepository(firestoreService: firestoreService);
});

/// ForageRequestRepository provider
///
/// Manages "Let's Forage Together" requests between users.
/// Handles the simplified connection flow with off-platform messaging.
final forageRequestRepositoryProvider = Provider<ForageRequestRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ForageRequestRepository(firestoreService: firestoreService);
});

/// EmergencyNotificationRepository provider
///
/// Manages emergency notifications sent to designated contacts
/// when a user plans to forage with someone new.
final emergencyNotificationRepositoryProvider =
    Provider<EmergencyNotificationRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return EmergencyNotificationRepository(firestoreService: firestoreService);
});

/// FollowingRepository provider
///
/// Manages one-way follow relationships (unlike Friends which are mutual).
/// Used for filtering posts/recipes by followed users.
final followingRepositoryProvider = Provider<FollowingRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FollowingRepository(firestoreService: firestoreService);
});

/// BookmarkRepository provider
///
/// Manages user bookmarks (saved locations) using subcollections.
final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return BookmarkRepository(firestoreService: firestoreService);
});

/// CollectionRepository provider
///
/// Manages location collections and subscriptions using subcollections.
final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return CollectionRepository(firestoreService: firestoreService);
});

/// ActivityFeedRepository provider
///
/// Manages the activity feed for friend updates.
final activityFeedRepositoryProvider = Provider<ActivityFeedRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ActivityFeedRepository(firestoreService: firestoreService);
});

/// SavedRecipeRepository provider
///
/// Manages user's saved/bookmarked recipes using subcollections.
final savedRecipeRepositoryProvider = Provider<SavedRecipeRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return SavedRecipeRepository(firestoreService: firestoreService);
});

/// PostMigrationService provider
///
/// Handles migration of Posts from array-based to subcollection-based architecture.
final postMigrationServiceProvider = Provider<PostMigrationService>((ref) {
  final postRepository = ref.watch(postRepositoryProvider);
  return PostMigrationService(postRepository: postRepository);
});

/// DirectMessageRepository provider
///
/// Manages private direct messages sent to admin.
/// Used for the Contact Us tab in the Feedback screen.
final directMessageRepositoryProvider = Provider<DirectMessageRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return DirectMessageRepository(firestoreService: firestoreService);
});

/// RoadmapRepository provider
///
/// Manages roadmap/changelog items displayed in the Feedback screen.
/// Admin users can add, update, and delete roadmap entries.
final roadmapRepositoryProvider = Provider<RoadmapRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return RoadmapRepository(firestoreService: firestoreService);
});

/// PostDraftRepository provider
///
/// Manages draft and scheduled community posts.
/// Drafts are stored in user subcollections for privacy.
final postDraftRepositoryProvider = Provider<PostDraftRepository>((ref) {
  return PostDraftRepository();
});

/// NotificationService provider
///
/// Manages push notifications via Firebase Cloud Messaging.
/// Handles token management, foreground notifications, and tap handling.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});
